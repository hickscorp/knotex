defmodule Knot.Repo.Migrations.CreateBlocks do
  use Ecto.Migration

  def change do
    create table(:blocks, primary_key: false) do
      add :hash,            :string,  primary_key: true
      add :height,          :bigint,  null: false
      add :timestamp,       :bigint,  null: false
      add :parent_hash,     :string,  null: false, size: 64
      add :content_hash,    :string,  null: false, size: 64
      add :component_hash,  :string,  null: false, size: 64
      add :nonce,           :bigint,  null: false
    end

    create index :blocks, [:hash], unique: true
    create index :blocks, [:parent_hash]
    create index :blocks, [:height]
  end
end
