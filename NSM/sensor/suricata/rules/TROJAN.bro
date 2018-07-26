
@load base/frameworks/notice
module HTTP;
export{
  redef enum Notice::Type += {
    Banking_TROJAN_Ransomware,
  };

event http_entity_data(c: connection, is_orig: bool, length: count, data: string)
  {
  if ( is_orig )
    {
    return;
    }
  if ( c$http$method == "GET" && /\.php?SSTART=/ in c$http$uri && /\&WIN/ in c$http$uri && /\WALLET=/ in c$http$uri)
    {
    NOTICE([$note=Banking_TROJAN_Ransomware,
      $msg=fmt("%s host",host)
    ]);
    }
  if ( c$http$method == "GET" && /\.php?RIGHTS=/ in c$http$uri && /\&WIN/ in c$http$uri && /\&ID=/ in c$http$uri && /\&UI/ in c$http$uri)
    {
    NOTICE([$note=Banking_TROJAN_Ransomware,
      $msg=fmt("%s host",host)
    ]);
    }
  
  }
    