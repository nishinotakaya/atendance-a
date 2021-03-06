# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
User.create!(name: "Sample User",
             email: "sample@email.com",
             employee_number: 1,
             password: "password",
             password_confirmation: "password",
             admin: true)
             
User.create!(name: "上長A",
             email: "superior-1@email.com",
             employee_number: 2,
             password: "password",
             password_confirmation: "password",
             superior: true)

User.create!(name: "上長B",
             email: "superior-2@email.com",
             employee_number: 3,
             password: "password",
             password_confirmation: "password",
             superior: true)
             
Office.create!(office_name: "拠点A",
               office_number: "1",
               office_modality: "出勤"
               )             

            

3.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = "password"
  User.create!(name: name,
               email: email,
               employee_number: n+4,
               password: password,
               password_confirmation: password)
               
end