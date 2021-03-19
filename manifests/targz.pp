#
# == Definition: mediafetch::targz
#
define mediafetch::targz ($source, $target) {

  exec { "${name} unpack":
    command => "curl  -m 1200 ${source} | tar -xzf - -C ${target} && touch ${name}",
    creates => $name,
    require => Package[curl],
  }

}
