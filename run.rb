#!/usr/bin/env ruby

require 'net/https'
require 'json'
require 'parallel'

## Configuration
email = 'johnDoe@gmail.com'

# Number of processes to run in parallel = #cores.
jobs  = 1

### --------------------------------- ###
base_url       = 'https://9zld4zwegj.execute-api.us-east-1.amazonaws.com/dev'
challenge_url  = base_url + '/challenge/start'
challenge_post = base_url + '/challenge/submission'

def post(url, body)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  req = Net::HTTP::Post.new(uri)
  req.body = body.to_json unless body.nil?
  http.request(req).body
end

def get(url)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  req =  Net::HTTP::Get.new(uri)
  http.request(req).body
end

def is_infected?(patient)
  dna = patient.bytes.each_with_object(Hash.new(0)) do |m,h|
    h[m] += 1
  end.sort_by{ |k,v| v }
  dna[4][0] == 84 && (dna[4][1] != dna[3][1])
end

data = JSON.parse(post(challenge_url, { 'email' => email }))
id   = data['populationId']

infections = Parallel.map(data['population'], in_processes: jobs) do |p|
  is_infected?(get(p))
end

s = infections.count(true) * 100 / data['population'].length.to_i
p post(challenge_post, { 'populationId' => id, 'sicknessPercentage' => s })
