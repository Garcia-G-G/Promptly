puts "Seeding database..."

owner = User.find_or_create_by!(email: ENV.fetch("SEED_OWNER_EMAIL", "owner@promptly.dev")) do |u|
  u.password = ENV.fetch("SEED_OWNER_PASSWORD", "promptly-dev")
  u.name = "Demo Owner"
end
owner.confirm unless owner.confirmed?

workspace = Workspace.find_or_create_by!(slug: "demo") do |w|
  w.name = "Demo"
  w.owner = owner
end

Membership.find_or_create_by!(workspace: workspace, user: owner) do |m|
  m.role = :owner
end

Project.find_or_create_by!(workspace: workspace, slug: "playground") do |p|
  p.name = "Playground"
end

puts "Seeding complete."
puts "  Owner: #{owner.email}"
puts "  Workspace: #{workspace.slug}"
puts "  Project: playground"
