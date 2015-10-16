#sequel -m db/migrations sqlite://db/development.db

Sequel.migration do
	up do
	  create_table :relationships do
        primary_key :id
        String :inviter_id
        String :invitee_id
        String :status # 0 - invited 1 - accepted 2 - rejected
      end
	end
	down do
	  drop_table :relationships
	end
end