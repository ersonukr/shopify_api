class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :product_id
      t.string :title
      t.text :body_html
      t.text :dump
      t.string :status

      t.timestamps
    end

  end
end
