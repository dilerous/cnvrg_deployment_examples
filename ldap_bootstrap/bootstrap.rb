#!/usr/bin/env ruby

puts 'Creating Admin User'
User.create(email:"bradley.soper@cnvrg.io",username:"bsoper",admin:"true")

puts 'Creating Organization'
user=User.find_by(username:"bsoper")
Organization.create(user_id: user.id, slug: 'cnvrg')
