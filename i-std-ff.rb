require 'rubygems'
require 'fcntl'
require 'optparse'
require 'thread'

#Credits:
#http://eric.lubow.org/2010/ruby/multiple-input-locations-from-bash-into-ruby/

class GenericInput
  attr_reader :queue

  def initialize(options)
    @threads = Array.new
    @stdin_proc=options[:stdin]
    @files_proc=options[:files]
    @queue={}
  end

  def stdin
    $stdin.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)
    @threads[0]=Thread.new {
      out=[]
      begin
	$stdin.each_line do |line|  
	  out<<@stdin_proc.call(line) 
	end
      rescue Errno::EAGAIN
	@threads.delete(0) # Remove this thread since we won't be reading from $stdin
      end
      @queue.merge!({stdin: out})
    }.join # not run to avoid thread kill
    #i-std-ff.rb:18:in `run': killed thread (ThreadError)
    #from i-std-ff.rb:18:in `stdin'
    #from i-std-ff.rb:64:in `<main>'

  end

  def files(files_names=[])
    files_names.each do |file_name|
      @threads.push Thread.new {
	out=[]
	File.open(file_name, 'r') do |ff|
	  ff.each_line do |line| #do stuff with line
	    out<< @files_proc.call(line)
	  end #line
	end #open
	# do stuff with 'file'
      @queue.merge!({file_name=> out})
      } #thread
    end#file_names
    #   # Put it all together and have the threads run
    @threads.each { |thread|  thread.join }
  end#files

end # class GenIn



args=ARGV
#@opts=OptionParser.new

#@opts.parse!(args)
files=args

input=GenericInput.new(:stdin=> Proc.new do |line| "I'm the STanDar INput: #{line}" end,
		:files=> Proc.new do |line| "Naaa I'm an input file: #{line}" end
	       )

input.stdin
input.files(args)

puts input.queue.keys
