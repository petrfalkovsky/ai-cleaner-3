require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Найти Runner target
runner_target = project.targets.find { |t| t.name == 'Runner' }

# Найти группу Runner
runner_group = project.main_group.groups.find { |g| g.name == 'Runner' }

# Добавить файл VisionFrameworkHandler.swift
file_ref = runner_group.new_reference('VisionFrameworkHandler.swift')

# Добавить в compile sources
runner_target.add_file_references([file_ref])

project.save

puts "✅ VisionFrameworkHandler.swift добавлен в проект"
