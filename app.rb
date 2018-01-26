require 'base64'
require 'securerandom'
require 'erb'
require 'tmpdir'
require 'sinatra'
require 'sinatra/streaming'
require 'tempfile'

configure do
	use Rack::Session::Cookie, :secret => "some unique secret string here"
	enable :sessions
end

get '/' do 
	csrf = (session['csrf'] ||= SecureRandom.hex)
	erb :index, :locals => { :csrf => csrf }
end

def check_csrf
	raise 'Incorrect CSRF' if params['csrf'] != session['csrf'] or session['csrf'] == nil
end

post '/download/' do 
	
	check_csrf

	content_type 'audio/flac'

	final = Tempfile.new('sts', Dir.tmpdir)
	final.close
	
	raise "Invalid file" if !params[:file][:filename]

	file_name = params[:file][:filename]
	ext = File.extname(file_name)

	file_name = File.basename(file_name, ext)

	raise "Invalid extension" unless ["mp3", "flac", "wav", "ogg"].include?(ext[1..-1])

	`avconv -i "#{params[:file][:tempfile].path}" -f wav -acodec pcm_s16le -ac 2 - | stereo_tool_cmd - - -s ./config.sts | avconv -i - -c:a flac -f flac -y #{final.path}`

	puts "Calling send_file on #{final.path}"
	
	send_file Dir.tmpdir + "/" + file, { :disposition => 'attachment', :filename => "#{file_name}.processed.flac", :type => 'flac' }
	#redirect "/file/" + File.basename(final.path) + "?fn=" + Base64::urlsafe_encode64(file_name)

end

get '/file/:file' do | file |
		
	next if file[0..2] != "sts" or file.include? "/"
	file_name = Base64::urlsafe_decode64(params[:fn]) rescue "untitled"
	
	send_file Dir.tmpdir + "/" + file, { :disposition => 'attachment', :filename => "#{file_name}.processed.flac", :type => 'flac' }
	
end

Thread.new do | a |

	loop do
	
		Dir.glob(Dir.tmpdir + "/sts*").each do | path |
			data = `lsof #{path}`
			next if data.to_s.length > 5
			# The file isn't being read, we can close it
			sleep 5
			puts "Re-checking #{path}"
			data = `lsof #{path}`
			next if data.to_s.length > 5
			puts "File hasn't been opened in the past 5 seconds, likely clean-up able"
		
			File.unlink(path)
		end
		sleep 5

	end
end

