#
# == Definition: mediafetch::zip
#
define mediafetch::zip ($source, $target) {

  exec { "${name} unpack":
    command => "TMPFILE=\$(mktemp); curl -m 1200 -o \${TMPFILE}.zip ${source} && unzip \${TMPFILE}.zip -d ${target} && rm \$TMPFILE && rm \${TMPFILE}.zip && touch ${name}",
    creates => $name,
    require => Package['unzip'],
  }

}
