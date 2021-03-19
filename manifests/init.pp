#
# == Definition: mediafetch
#
# Fetch files from the Media Library
# This define is used to retrieve and eventually unpack files from the medialibrary.
# The url from where files are retrieved can be specified with 2 alternative methods:
#  - the single $url parameter (should contain the full url (credentials included) of the file to fetch
#  - multiple $url_* parameters that define the single components that define the location of the file on the medialibrary
#
# === Parameters:
#
# [*target*]
#   Destination download directory. If empty, the file is placed in the $cache_dir
#
# [*url*]
#   Full url of the file to download. Use it or the whole set of url_* parameters.
#
# [*ensure*]
#   Set to 'absent' if you want to delete a previously downloaded file (and extracted dirs). Default value "present"
#
# [*checksum*]
#   If to verify the checksum of downloaded file matched the one defined in the digest_url or digest_string parameters. Default value "true"
#
# [*digest_url*]
#   If checksum is enabled the url of a file containing the checks. Default value is automatically based on the $url and $digest_type parameters: $url.$digest_type.
#
# [*digest_string*]
#   If checksum is enabled the actual checksum of the downloaded file. This option is alternative to $digest_url. Default value ""
#
# [*digest_type*]
#   If checksum is enabled the digest algorithm to use. Default value "md5" (Allowed values: 'md5','sha1','sha224','sha256','sha384','sha512')
#
# [*cache_dir*]
#   The cache directory where files are downloaded. Default value "/var/cache/medialibrary"
#
# [*extracted_name*]
#   The name of the directory or file contained in an archive, if different from the archive name withput its suffix. Default value ""
#
# [*extension*]
#   The archive extension. Define it only if you need to unpack the downloaded file to $target. Otherwise leave the default value ""
#
# [*timeout*]
#   Timeout in seconds for the download and extract operations. Default value 120. Raise it if you encounter download timeouts.
#
# [*allow_insecure*]
#   Accept downloads from https with not verified certificates. Default value true.
#
# [*allow_resume*]
#   Accept resume of incomplete downloads. Default value true.
#
# [*url_medialibrary*]
#   Base host name or IP of the Media Library server
#
# [*url_username*]
#   Optional username to use to access the http(s) source
#
# [*url_password*]
#   Optional password to use to access the http(s) source
#
# [*url_access_level*]
#   Default value 'private',
#
# [*url_organization*]
#   Define the organization level on the medialibrary (ie: oracle). Default value ""
#
# [*url_group*]
#   Define the group level on the medialibrary (ie: java, weblogic...). Default value ""
#
# [*url_product*]
#   Define the product level on the medialibrary (ie: server, portal...). Default value ""
#
# [*url_os*]
#   Define the os level on the medialibrary (ie: linux, windows, generic...). Default value ""
#
# [*url_arch*]
#   Define the arch level on the medialibrary (ie: x86, x86_64). Default value ""
#
# [*url_version*]
#   Define the version level on the medialibrary. Default value ""
#
# [*owner*]
#   Owner of the downloaded and extracted file. Default value 'root'.
#
# [*group*]
#   Group of the downloaded and extracted file. Default value 'root'.
#
# [*exec_env*]
#   Environment variables to set for the commands executed. Default value ''.
#
# [*exec_path*]
#   Path to use for the commands executed. Default value '/usr/bin:/usr/sbin:/bin:/sbin'
#
# === Example usage:
#
#  mediafetch { "apache-tomcat-6.0.26":
#    url => "http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.26/bin/apache-tomcat-6.0.26.tar.gz",
#  }
#
define mediafetch (
  $ensure           = present,
  $url              = '',
  $url_scheme       = '',
  $url_medialibrary = $::media_library_host,
  $url_username     = '',
  $url_password     = '',
  $url_access_level = 'private',
  $url_organization = '',
  $url_group        = '',
  $url_product      = '',
  $url_os           = '',
  $url_arch         = '',
  $url_version      = '',
  $url_extension    = '',
  $checksum         = true,
  $digest_url       = '',
  $digest_string    = '',
  $digest_type      = 'md5',
  $target           = '',
  $cache_dir        = '/var/cache/medialibrary',
  $extracted_name   = '',
  $extract          = false,
  $timeout          = 120,
  $allow_insecure   = false,
  $allow_resume     = true,
  $owner            = 'root',
  $group            = undef,
  $exec_env         = [],
  $exec_path        = '/usr/bin:/usr/sbin:/bin:/sbin') {

  if $url == '' {
    if $url_medialibrary == '' or
      $url_access_level == '' or
      $url_organization == '' or
      $url_group == '' or
      $url_product == '' or
      $url_os == '' or
      $url_arch == '' or
      $url_version == '' or
      $url_extension == '' {
      fail "If you do not specify a full url for ${title}, you MUST specify all the single url_* elements!"
    }
  }

  $calc_url_scheme = $url ? {
    ''        => 'http://',
    default   => url_parse($url, scheme),
  }

  $real_scheme = $url_scheme ? {
    '' => $url_access_level ? {
      'private' => 'https://',
      'public'  => 'https://',
      default   => "${calc_url_scheme}://",
    },
    default => $url_scheme,
  }

  $real_target = $target ? {
    ''      => $cache_dir,
    default => $target,
  }

  $real_filename = $url ? {
    ''      => "${url_product}-${url_version}-${url_os}-${url_arch}.${url_extension}",
    default => url_parse($url, filename),
  }

  $calc_extension = $url_extension ? {
    ''      => url_parse($url, filetype),
    default => $url_extension,
  }

  $real_extension = $calc_extension ? {
    '.gz'      => is_tar($real_filename) ? {
      true    => 'tar.gz',
      default => 'gz',
    },
    '.bz2'     => is_tar($real_filename) ? {
      true    => 'tar.bz2',
      default => 'bz2',
    },
    default => regsubst($calc_extension,'^\.',''),
  }

  $real_url = $url ? {
    ''      => $url_username ? {
      ''      => "${real_scheme}${url_medialibrary}/${url_access_level}/${url_organization}/${url_group}/${url_product}/${real_filename}",
      default => "${real_scheme}${url_username}:${url_password}@${url_medialibrary}/${url_access_level}/${url_organization}/${url_group}/${url_product}/${real_filename}"
    },
    default => $url,
  }

  $real_group = $group ? {
    undef   => $owner,
    default => $group
  }

  require mediafetch::prerequisites

  if !defined(File[$cache_dir]) {
    # Create the $cache_dir (parent must exist).
    file { $cache_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  }

  # Download file.
  mediafetch::download { $real_filename:
    ensure         => $ensure,
    url            => $real_url,
    checksum       => $checksum,
    digest_url     => $digest_url,
    digest_string  => $digest_string,
    digest_type    => $digest_type,
    timeout        => $timeout,
    cache_dir      => $cache_dir,
    allow_insecure => $allow_insecure,
    allow_resume   => $allow_resume,
    exec_env       => $exec_env,
    exec_path      => $exec_path,
    owner          => $owner,
    group          => $real_group,
  }

  if $extract {
    # Extract archive if needed.
    mediafetch::extract { $real_filename:
      ensure         => $ensure,
      target         => $real_target,
      cache_dir      => $cache_dir,
      extracted_name => $extracted_name,
      extension      => $real_extension,
      timeout        => $timeout,
      require        => Mediafetch::Download[$real_filename],
      exec_env       => $exec_env,
      exec_path      => $exec_path,
      owner          => $owner,
      group          => $real_group,
    }
  }

}


