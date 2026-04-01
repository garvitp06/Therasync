require 'xcodeproj'

project_path = 'OT main.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'OT main' } || project.targets.first

# The path relative to the project directory
file_path = 'OT main/OT Side/TabbarFiles/Appointments/EditAppointmentViewController.swift'

# Find the group
group_path = 'OT main/OT Side/TabbarFiles/Appointments'
group = project.main_group
group_path.split('/').each do |folder|
  group = group.children.find { |c| c.display_name == folder || c.path == folder } || group.new_group(folder)
end

# Check if file already exists in the project
unless group.files.any? { |f| f.path == 'EditAppointmentViewController.swift' }
  file_ref = group.new_reference('EditAppointmentViewController.swift')
  target.source_build_phase.add_file_reference(file_ref)
  project.save
  puts "Added EditAppointmentViewController.swift to project."
else
  puts "File already in project."
end
