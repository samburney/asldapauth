CREATE TABLE `cache` (
  `cache_key` varchar(255) NOT NULL,
  `cache_value` varchar(255) NOT NULL,
  `cache_time` int(11) NOT NULL,
  `cache_ttl` int(11) NOT NULL,
  PRIMARY KEY (`cache_key`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
