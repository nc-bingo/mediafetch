#
# == Class mediafetch::prerequisites
#
class mediafetch::prerequisites {

  if !defined(Package['curl']) {
    package { 'curl': ensure => present, }
  }

  if !defined(Package['unzip']) {
    package { 'unzip': ensure => present, }
  }

  if !defined(Package['gzip']) {
    package { 'gzip': ensure => present, }
  }

  if !defined(Package['bzip2']) {
    package { 'bzip2': ensure => present, }
  }

}


