#!/usr/bin/env ruby

username=""
email=""
organization=""

puts 'Creating Admin User'
User.create(email: email, username: username, admin: "true")

puts 'Creating Organization'
user=User.find_by(username: username)
Organization.create(user_id: user.id, slug: organization)
