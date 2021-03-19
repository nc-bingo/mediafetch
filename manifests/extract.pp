#
# === Definition: mediafetch::extract
#
# Archive extractor.
#
# NOTE:
# The parameter *$extracted_name* must be used if the extracted directory (or file) of the archive
# is different from the name of the archive *$name*. To extract the name of
# the root directory use the commands "tar tf archive.tar.gz" or
# "unzip -l archive.zip"
#
define mediafetch::extract (
  $target,
  $ensure         = present,
  $cache_dir      = '/usr/src',
  $extracted_name = '',
  $extension      = 'tar.gz',
  $timeout        = 120,
  $exec_env       = [],
  $owner          = 'root',
  $group          = 'root',
  $exec_path      = '/usr/bin:/usr/sbin:/bin:/sbin'
  ) {

  $calc_extracted_name = regsubst($name, ".${extension}", '')

  if $extracted_name != '' {
    $extracted_files = "${target}/${extracted_name}"
  } else {
    $extracted_files = "${target}/${calc_extracted_name}"
  }

  if !defined(Package['unzip']) {
    package { 'unzip': ensure => present }
  }

  case $ensure {

    present: {

      $extract_zip    = "unzip -o ${cache_dir}/${name} -d ${target}"
      $extract_gz     = "gzip -dc ${cache_dir}/${name} > ${extracted_files}"
      $extract_bz2    = "bzip2 -dc ${cache_dir}/${name} > ${extracted_files}"
      $extract_targz  = "tar --no-same-owner --no-same-permissions -xzf ${cache_dir}/${name} -C ${target}"
      $extract_tarbz2 = "tar --no-same-owner --no-same-permissions -xjf ${cache_dir}/${name} -C ${target}"

      $extract_command = $extension ? {
        'zip'     => $extract_zip,
        'tar.gz'  => $extract_targz,
        'tgz'     => $extract_targz,
        'tar.bz2' => $extract_tarbz2,
        'tgz2'    => $extract_tarbz2,
        'gz'      => $extract_gz,
        'bz2'     => $extract_bz2,
        default   => "cp -p ${target}",
      }

      if (!defined(Exec["create unpack directory ${target}"])) {
        # Ensure target directory exists.
        exec { "create unpack directory ${target}":
          command => "mkdir -p ${target}",
          creates => $target,
          before  => Exec["unpack ${name}"],
          path    => '/usr/bin:/bin:/usr/sbin:/sbin',
        }
      }

      # Unpack archive.
      exec {"unpack ${name}":
        command     => $extract_command,
        creates     => $extracted_files,
        timeout     => $timeout,
        path        => $exec_path,
        environment => $exec_env,
        unless      => "test `find ${extracted_files} -maxdepth 1 | wc -l` -gt 1",
        notify      => Common::Ownership[$extracted_files],
        require     => [
          Class['mediafetch::prerequisites'],
          Exec["create unpack directory ${target}"],
        ]
      }

      # Give proper permissions to extracted files.

      common::ownership { $extracted_files:
        recurse     => true,
        user        => $owner,
        group       => $group,
        refreshonly => true,
        require     => [
          Exec["unpack ${name}"],
          Exec["create unpack directory ${target}"],
        ]
      }

    }

    absent: {

      # Delete extracted files.
      file { $extracted_files:
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
        backup  => false,
      }

    }

    default: { err ( "Unknown ensure value: '${ensure}'" ) }

  }

}


