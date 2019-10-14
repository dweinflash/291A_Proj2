require 'sinatra'
require 'digest'
require 'google/cloud/storage'

storage = Google::Cloud::Storage.new(project_id: 'cs291-f19')
bucket = storage.bucket 'cs291_project2', skip_lookup: true

get '/' do
  redirect to('/files/'), 302
end

get '/files/' do

  gcs = nil
  arr = Array.new
  files = bucket.files
  
  files.all do |file|
    gcs = file.name
    gcs.slice!(2)
    gcs.slice!(4)
    gcs = gcs.downcase
    next if (gcs =~ /[^A-Fa-f0-9]/) != nil
    next if gcs.length != 64
    arr.push(gcs)
  end  

  arr.sort
  [ 200, arr.to_json ]

end

get '/files/:digest' do

  gcs = nil
  file = nil
  dl = nil
  ctype = nil

  if (params['digest'] =~ /[^A-Fa-f0-9]/) != nil
    422
  elsif params['digest'].length != 64
    422
  else
    gcs = params['digest']
    gcs = gcs.downcase
    gcs = gcs.insert(2,'/')
    gcs = gcs.insert(5,'/')
    file = bucket.file gcs
    if file == nil
      404
    else
      dl = file.download
      ctype = file.content_type
      [ 200, {'Content-Type' => ctype}, dl ]
    end
  end

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
      gcs = gcs.downcase
      gcs = gcs.insert(2,'/')
      gcs = gcs.insert(5,'/')
      file = bucket.file gcs
      if file == nil
        bucket.create_file tmpfile, gcs

        file = bucket.file gcs
        file.update do |f|
          f.content_type = params[:file][:type]
        end

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
    gcs = gcs.downcase
    gcs = gcs.insert(2,'/')
    gcs = gcs.insert(5,'/')
    file = bucket.file gcs
    if file != nil
      file.delete
    end
  end

end
