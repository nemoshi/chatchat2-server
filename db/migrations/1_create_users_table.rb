#sequel -m db/migrations sqlite://db/development.db

Sequel.migration do
	up do
	  create_table :users do
        primary_key :id
        String :name
        String :portrait
        String :user_token
        String :gender
        String :phone_number
        String :desc
      end
	end
	down do
	  drop_table :resources
	end
end