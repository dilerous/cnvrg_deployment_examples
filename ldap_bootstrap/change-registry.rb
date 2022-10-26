#!/usr/bin/env ruby

repourl=""
organization=""


org = Organization.find_by(slug: organization)
r = Registry.where(organization_id: org.id, title:"cnvrg").last
r.update(url: repourl)
puts 'Internal Repo updated'



