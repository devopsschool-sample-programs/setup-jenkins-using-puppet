# @summary A short summary of the purpose of this class
#
# A description of what this class does
# This class is for master node
#
# @example
# include dof_jenkins
class jenkins (
#$list_of_plugins = undef,
$list_of_plugins = ['msbuild', 'active-directory']
#$bind_password = undef,
){

package { wget:
ensure => present,
}

exec { 'sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo --no-check-certificate':
  cwd     => '/var/tmp',
  path    => ['/usr/bin', '/usr/sbin',],
}

exec { 'sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key':
  cwd     => '/var/tmp',
  path    => ['/usr/bin', '/usr/sbin',],
}

$packages = ['java-11-openjdk-demo.x86_64', 'jenkins']

package { $packages:
ensure => present,
}

file {'/usr/lib/systemd/system/jenkins.service':
	ensure => present,
	mode => '0644',
	owner => 'root',
	group => 'root',
	source => 'puppet:///modules/jenkins/jenkins.service',
	#notify => Exec['/usr/bin/systemctl daemon-reload'],
}



file {'/var/lib/initialAdminPassword':
	ensure => present,
	mode => '0644',
	owner => 'jenkins',
	group => 'jenkins',
	source => 'puppet:///modules/jenkins/initialAdminPassword',
	}
	
file {'/var/lib/jenkins/secrets/master.key':
	ensure => present,
	mode => '0644',
	owner => 'jenkins',
	group => 'jenkins',
	source => 'puppet:///modules/jenkins/master.key',
	}


exec {'/usr/bin/systemctl daemon-reload':
refreshonly => true,
}



service {'jenkins':
ensure => running,
enable => true,
hasrestart => true,
hasstatus => true,
}



#$file_path = '/var/lib/creds'
#$file_exists = find_file($file_path)

#if !$file_exists {
#fail('Credentials file not found under /var/lib/jenkins with name creds')
#}


# file {'/var/lib/jenkins/proxy.xml':
# ensure => present,
# mode => '0644',
# owner => 'jenkins',
# group => 'jenkins',
# source => 'puppet:///modules/dof_jenkins/proxy.xml',
# notify => [Exec['/usr/bin/systemctl daemon-reload'],
# Service['jenkins']],
# }



exec { 'wget http://localhost:8080/jnlpJars/jenkins-cli.jar -P /var/lib/jenkins':
  cwd     => '/var/tmp',
  path    => ['/usr/bin', '/usr/sbin',],
}

# file {'/var/lib/jenkins/jenkins.yaml':
# ensure => present,
# mode => '0644',
# owner => 'jenkins',
# group => 'jenkins',
# source => 'puppet:///modules/dof_jenkins/Jenkins.yaml',
# notify => [Exec['/usr/bin/systemctl daemon-reload'],
# Service['jenkins']],
# }

$list_of_plugins.each | String $plugin | {
exec {"${plugin}":
command => "java -jar /var/lib/jenkins/jenkins-cli.jar -s http://localhost:8080/ -auth @/var/lib/initialAdminPassword install-plugin $plugin",
path => '/usr/bin:/usr/sbin:/sbin',
#onlyif => "java -jar /var/lib/jenkins/jenkins-cli.jar -s http://localhost:8080/ -auth @/var/lib/initialAdminPassword $plugin",
creates => "/var/lib/jenkins/plugins/${plugin}*.jpi",
}
}

# file {'/run/secrets/secrets.properties':
# ensure => 'file',
# content => template('dof_jenkins/secrets.properties.erb')
# }
}
