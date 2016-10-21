#!/usr/bin/php
<?php
require_once('/usr/local/share/asldapauth/asldapauth-config.php');

require_once('MDB2.php');
$db =& MDB2::connect($dsn);
if(PEAR::isError($db)){
	echo $db->getUserinfo() . "\n";
	exit(2);
}
$db->setFetchMode(MDB2_FETCHMODE_ASSOC);

// Store value in cache
function dbcache_store($key, $value, $ttl=30){
	global $db;

	$cache_time = date('U');
	$sql = "replace into cache (cache_key, cache_value, cache_time, cache_ttl) values (" . $db->quote($key) . ", " . $db->quote($value) . ", $cache_time, " . $db->quote($ttl) . ")";
	$result = $db->exec($sql);
	if(PEAR::isError($result)){
		echo $result->getUserinfo() . "\n";
		exit(2);
	}
}

// Fetch value from cache
function dbcache_fetch($key){
	global $db;
	
	$sql = "select * from cache where cache_key = " . $db->quote($key);
	$result = $db->queryRow($sql);
	if(PEAR::isError($result)){
		echo $result->getUserinfo() . "\n";
		exit(2);
	}
	else{
		if($result){
			$cache = $result;
			
			// If cache is fresh, return value
			if($cache['cache_time'] + $cache['cache_ttl'] >= date('U')){
				return $cache['cache_value'];
			}

			// If not, remove entry from cache
			else{
				$sql = "delete from cache where cache_key = " . $db->quote($key);
				$result = $db->exec($sql);
				if(PEAR::isError($result)){
			                echo $result->getUserinfo() . "\n";
					exit(2);
			        }
			}
		}
	}

	return false;
}

$h = fopen('php://stdin', 'r');
$input = fread($h, 8192);
list($user, $pass) = explode("\n", $input);

// Escape user/pass before it's sent to exec()
$user = escapeshellarg($user);
$pass = escapeshellarg($pass);

// Check user/pass against cache, if not matched query LDAP
if($status = dbcache_fetch('asldapauth_' . sha1($user . sha1($pass)))){
	exit(0);
}
else{
	exec("ldapsearch -H ldaps://mail.air-stream.org:636 -D uid=$user,ou=people,dc=air-stream,dc=org -w $pass uid=$user", $output, $status);
}

if($status == 0 || $status == 32){
	// Cache for 60 minutes
	dbcache_store('asldapauth_' . sha1($user . sha1($pass)), $status, 3600);

	exit(0);
}
else{
	exit(1);
}
?>
