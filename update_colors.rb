require 'fileutils'

Dir.glob('/Users/user54/Downloads/Therasync/OT main/Parent Side/**/*.swift').each do |file|
  content = File.read(file)
  new_content = content
    .gsub(/(\.|\b)backgroundColor\s*=\s*\.white\b/, '\1backgroundColor = .systemBackground')
    .gsub(/(\.|\b)textColor\s*=\s*\.black\b/, '\1textColor = .label')
    .gsub(/(\.|\b)textColor\s*=\s*\.darkGray\b/, '\1textColor = .secondaryLabel')
    .gsub(/UIColor\.white\b/, 'UIColor.systemBackground')
    .gsub(/UIColor\.black\b/, 'UIColor.label')
    .gsub(/UIColor\.darkGray\b/, 'UIColor.secondaryLabel')
    .gsub(/UIColor\(red: 0\.0, green: 0\.48, blue: 1\.0, alpha: 1\.0\)/, 'UIColor.systemBlue')
    .gsub(/UIColor\(red: 0, green: 0\.48, blue: 1, alpha: 1\)/, 'UIColor.systemBlue')
    .gsub(/UIColor\.blue\.withAlphaComponent/, 'UIColor.systemBlue.withAlphaComponent')
    .gsub(/UIColor\.black\.withAlphaComponent/, 'UIColor.label.withAlphaComponent')
    .gsub(/UIColor\(white: 0\.95, alpha: 1\.0\)/, 'UIColor.secondarySystemBackground')
  
  if new_content != content
    File.write(file, new_content)
    puts "Updated: #{file}"
  end
end
