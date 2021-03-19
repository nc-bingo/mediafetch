#
# == Definition: mediafetch::download
#
# Archive downloader with integrity verification.
#
define mediafetch::download (
  $url,
  $ensure         = present,
  $checksum       = true,
  $digest_url     = '',
  $digest_string  = '',
  $digest_type    = 'md5',
  $timeout        = 1200,
  $cache_dir      = '/var/cache/medialibrary',
  $allow_insecure = true,
  $allow_resume   = true,
  $owner          = 'root',
  $group          = 'root',
  $exec_env       = [],
  $exec_path      = '/usr/bin:/usr/sbin:/bin:/sbin') {

  $insecure_arg = $allow_insecure ? {
    true    => '-k',
    default => '',
  }

  $resume_arg = $allow_resume ? {
    true    => '-C - ',
    default => '',
  }

  $real_arg = "-f -L -sS ${insecure_arg} ${resume_arg}"

  #######################################################################
  # Checksum management.
  #######################################################################

  if $checksum {

    # Definition of checksum command.
    case $digest_type {
      'md5', 'sha1', 'sha224', 'sha256', 'sha384', 'sha512' : { $checksum_cmd = "${digest_type}sum -c ${name}.${digest_type}" }
      default : { fail 'Unimplemented digest type' }
    }

    # Check of method used to supply digest.
    if $digest_url != '' and $digest_string != '' {
      fail 'digest_url and digest_string should not be used together !'
    }

    # Download of digest file.
    if $digest_string == '' {
      case $ensure {
        present : {

          if $digest_url == '' {
            $digest_src = "${url}.${digest_type}"
          } else {
            $digest_src = $digest_url
          }

          # Download checksum file.
          exec { "download digest of archive ${name}":
            command     => "curl ${real_arg} -o ${cache_dir}/${name}.${digest_type} ${digest_src}",
            creates     => "${cache_dir}/${name}.${digest_type}",
            timeout     => $timeout,
            notify      => Exec["download archive ${name} and check sum"],
            require     => [ Package['curl'], File[$cache_dir] ],
            path        => $exec_path,
            environment => $exec_env,
          }

          # Give proper permissions to the checksum file.
          file { "${cache_dir}/${name}.${digest_type}":
            ensure      => present,
            owner       => $owner,
            group       => $group,
            backup      => false,
            require     => Exec["download digest of archive ${name}"]
          }

        }
        absent  : {

          # Delete checksum file.
          file { "${cache_dir}/${name}.${digest_type}":
            ensure => absent,
            purge  => true,
            force  => true,
            backup => false,
          }

        }
        default: { }
      }
    }

    # Digest provided via digest_string parameter
    if $digest_string != '' {
      case $ensure {
        present : {

          # Create checksum file with digest content.
          file { "${cache_dir}/${name}.${digest_type}":
            ensure  => $ensure,
            content => "${digest_string} *${name}",
            notify  => Exec["download archive ${name} and check sum"],
            backup  => false,
            owner   => $owner,
            group   => $group,
          }

        }
        absent  : {

          # Delete checksum file.
          file { "${cache_dir}/${name}.${digest_type}":
            ensure => absent,
            purge  => true,
            force  => true,
            backup => false,
          }

        }
        default: { }
      }
    }
  }

  #######################################################################
  # Download management.
  #######################################################################

  case $ensure {
    present : {

      $notify_download = $checksum ? {
        true    => Exec["compare checksum for ${name}"],
        default => undef,
      }

      $refreshonly_download = $checksum ? {
        true    => true,
        default => undef,
      }

      # Download actual file.
      exec { "download archive ${name} and check sum":
        command     => "curl ${real_arg} -o ${cache_dir}/${name} ${url}",
        creates     => "${cache_dir}/${name}",
        logoutput   => true,
        timeout     => $timeout,
        require     => [ Package['curl'], File[$cache_dir] ],
        notify      => $notify_download,
        refreshonly => $refreshonly_download,
        path        => $exec_path,
        environment => $exec_env,
      }

      # Verify checksum.
      exec { "compare checksum for ${name}":
        command     => "rm -f ${cache_dir}/${name} ${cache_dir}/${name}.${digest_type}",
        unless      => $checksum_cmd,
        cwd         => $cache_dir,
        refreshonly => true,
        path        => $exec_path,
        environment => $exec_env
      }

      # Give proper permissions to the checksum file.
      file { "${cache_dir}/${name}":
        ensure      => present,
        owner       => $owner,
        group       => $group,
        backup      => false,
        require     => [
          Exec["download archive ${name} and check sum"],
          Exec["compare checksum for ${name}"],
        ]
      }

    }

    absent  : {
      # Delete downloaded file.
      file { "${cache_dir}/${name}":
        ensure => absent,
        purge  => true,
        force  => true,
        backup => false,
      }
    }

    default : {
      fail("Unknown ensure value: '${ensure}'")
    }

  }
}


