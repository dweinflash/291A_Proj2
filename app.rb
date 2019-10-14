require 'sinatra'
require 'digest'
require 'google/cloud/storage'

storage = Google::Cloud::Storage.new(project_id: 'cs291-f19')
bucket = storage.bucket 'cs291_project2', skip_lookup: true

get '/' do
  redirect to('/files/'), 302
end

get '/files/' do
end

post '/files/' do
  
  sha = nil
  gcs = nil
  file = nil
  tmpfile = nil
  s = nil

  begin
    tmpfile = params[:file][:tempfile]
    s = File.size(tmpfile)
    if s > 1048576
      422
    else 
      sha = Digest::SHA256.hexdigest tmpfile.read
      gcs = sha.dup
      gcs = gcs.insert(2,'/')
      gcs = gcs.insert(5,'/')
      file = bucket.file gcs
      if file == nil
        bucket.create_file tmpfile, gcs
        [ 201, { "uploaded" => sha }.to_json ]
      else
        409
      end
    end
  rescue
    422
  end

end

delete '/files/:digest' do
    
  gcs = nil
  file = nil

  if (params['digest'] =~ /[^A-Fa-f0-9]/) != nil
    422
  elsif params['digest'].length != 64
    422
  else
    gcs = params['digest']
    gcs = gcs.insert(2,'/')
    gcs = gcs.insert(5,'/')
    file = bucket.file gcs
    if file != nil
      file.delete
    end
  end
end
