require 'xcodeproj'
project = Xcodeproj::Project.open('OT main.xcodeproj')
target = project.targets.find { |t| t.name == 'OT main' } || project.targets.first

group_path = 'OT main/OT Side/PatientDetails'
group = project.main_group
group_path.split('/').each do |folder|
  group = group.children.find { |c| c.display_name == folder || c.path == folder } || group.new_group(folder)
end

unless group.files.any? { |f| f.path == 'PatientDetailFormViewController.swift' || f.path == 'OT main/OT Side/PatientDetails/PatientDetailFormViewController.swift' }
  file_ref = group.new_reference('PatientDetailFormViewController.swift')
  target.source_build_phase.add_file_reference(file_ref)
  project.save
  puts "Added PatientDetailFormViewController.swift to project."
else
  puts "File already in project."
end
