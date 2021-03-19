Facter.add(:media_library_host) do
  setcode do
    if File.exist?('/etc/medialibrary.host') then
        File.open('/etc/medialibrary.host') {|f| f.readline.chomp}
    else
        'ml.nchosting.dk'
    end
  end
end
