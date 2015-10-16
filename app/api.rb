require 'json'
require 'sinatra/base'
require 'digest/sha1'
require 'active_support/all'
require 'typhoeus'
require './config/sequel'

class ChachatApp < Sinatra::Base

	set :public_folder, Proc.new { File.join($project_root, "static") }

	before do
		if ['POST', 'PUT'].include?(request.request_method)
			body = request.body.read
			@request_payload = JSON.parse(body) if body.present?
		end
	end

	post '/api/v1/user/register' do
	    username = @request_payload['username']
	    portrait = @request_payload['portrait_url']
	    gender = @request_payload['gender']
	    desc = @request_payload['desc']

	    #save to DB and generate a id

	    id = User.insert({ :name => username, :portrait => portrait, :gender => gender, :desc => desc, :user_token => ""})
		
		content_type :json
	    status 200
	    {id: id}.to_json
	end

	get '/api/v1/user/:user_id' do

		user = User.with_pk!(params[:user_id])

		content_type :json
		status 200
		{user_id: user.id, username: user.name, gender: user.gender, portrait: user.portrait, desc: user.desc }.to_json
	end

	post '/api/v1/user/token' do
		url = "https://api.cn.ronghub.com/user/getToken.json"

		body = {}
		body[:userId] = @request_payload['user_id']
		body[:name] = @request_payload['username']
		body[:portraitUri] = @request_payload['portrait_url']

		opts = {method: :post, headers: generate_headers, body: body}
		response = Typhoeus::Request.new(url, opts).run

		result = JSON.parse(response.body)
		if response.success?
			content_type :json
			status result['code']
			{ token: result['token'] }.to_json
		else
			content_type :json
			status 503
			{ error_code: result['code'], error_message: result['errorMessage'] }.to_json
		end
	end

	get '/api/v1/user/nearby/:user_id' do
		users = []
		User.all.each do |user|
			users << {user_id: user.id, username: user.name, gender: user.gender, portrait: user.portrait, desc: user.desc } unless user.id == params[:user_id].to_i
		end

		content_type :json
		status 200
		users.to_json
	end

	get '/api/v1/friendship/:user_id' do
		friends = []

		user_id = params['user_id']

		Relationship.where(:inviter_id => user_id, :status => 0).all.each do |user|
			friend = User.with_pk!(user.invitee_id)
			friends << {user_id: friend.id, username: friend.name, gender: friend.gender, portrait: friend.portrait, desc: friend.desc , status: "request-sent"}
		end

		Relationship.where(:invitee_id => user_id, :status => 0).all.each do |user|
			friend = User.with_pk!(user.inviter_id)
			friends << {user_id: friend.id, username: friend.name, gender: friend.gender, portrait: friend.portrait, desc: friend.desc , status: "request-received" }
		end

		Relationship.where(:inviter_id => user_id, :status => 1).all.each do |user|
			friend = User.with_pk!(user.invitee_id)
			friends << {user_id: friend.id, username: friend.name, gender: friend.gender, portrait: friend.portrait, desc: friend.desc , status: "mutual-friend" }
		end

		Relationship.where(:invitee_id => user_id, :status => 1).all.each do |user|
			friend = User.with_pk!(user.inviter_id)
			friends << {user_id: friend.id, username: friend.name, gender: friend.gender, portrait: friend.portrait, desc: friend.desc , status: "mutual-friend" }
		end

		content_type :json
		status 200
		friends.to_json
	end

	post '/api/v1/friendship/:inviter_id/:invitee_id' do
		inviter_id = params['inviter_id']
		invitee_id = params['invitee_id']

		relationship = Relationship.find(:inviter_id => inviter_id, :invitee_id => invitee_id)
		if relationship
			relationship.update(:status => "0")
		else
			id = Relationship.insert({ :inviter_id => inviter_id, :invitee_id => invitee_id, :status => "0"})
			relationship = Relationship.with_pk!(id)
		end
		content_type :json
		status 200
		{id: relationship.id, inviter_id: inviter_id, invitee_id: invitee_id, status: relationship.status}.to_json
	end

	put '/api/v1/friendship/:inviter_id/:invitee_id' do
		inviter_id = params['inviter_id']
		invitee_id = params['invitee_id']
		
		relationship = Relationship.find(:inviter_id => inviter_id, :invitee_id => invitee_id)
		relationship.update(:status => "1")

		content_type :json
		status 200
		{id: relationship.id, inviter_id: inviter_id, invitee_id: invitee_id, status: "1"}.to_json
	end

	delete '/api/v1/friendship/:inviter_id/:invitee_id' do
		inviter_id = params['inviter_id']
		invitee_id = params['invitee_id']
		
		relationship = Relationship.find(:inviter_id => inviter_id, :invitee_id => invitee_id)
		relationship.update(:status => "2")

		content_type :json
		status 200
		{id: relationship.id, inviter_id: inviter_id, invitee_id: invitee_id, status: "2"}.to_json
	end

	private

	def generate_headers
		app_key = '8luwapkvu1u7l'
		app_secret = 'JdpKldTBpQW' # 开发者平台分配的 App Secret。
		nonce = Random.rand(9999) # 获取随机数。
		timestamp = Time.now.to_i # 获取时间戳。
		signature = Digest::SHA1.hexdigest("#{app_secret}#{nonce}#{timestamp}")

		{'App-Key' => app_key, 'Nonce' => nonce, 'Timestamp' => timestamp, 'Signature' => signature, 'Content-Type' => 'application/x-www-form-urlencoded' }
	end
end