//  MacFinder.m
//  MacFinder
//
//  Created by Michael Mavris on 08/06/16.
//  Copyright © 2016 Miksoft. All rights reserved.
//

#import "MacFinder.h"
#define BUFLEN (sizeof(struct rt_msghdr) + 512)
#define SEQ 9999
#define RTM_VERSION    5    // important, version 2 does not return a mac address!
#define RTM_GET    0x4    // Report Metrics
#define RTF_LLINFO    0x400    // generated by link layer (e.g. ARP)
#define RTF_IFSCOPE 0x1000000 // has valid interface scope
#define RTA_DST    0x1    // destination sockaddr present

@implementation MacFinder

+(NSData *)ipToRaw:(NSString *)strIP
{
    const char *ip = [strIP UTF8String];
    
    struct sockaddr_in ip4addr;
    
    ip4addr.sin_len = sizeof(struct sockaddr_in);
    ip4addr.sin_family = AF_INET;
    
    inet_pton(AF_INET, ip, &ip4addr.sin_addr);
    
    return [NSData dataWithBytes:&ip4addr length:sizeof(ip4addr)];
}

+(NSString*)ip2mac: (NSString*)strIP {
    
    const char *ip = [strIP UTF8String];
    
    int sockfd;
    unsigned char buf[BUFLEN];
    unsigned char buf2[BUFLEN];
    ssize_t n;
    struct rt_msghdr *rtm;
    struct sockaddr_in *sin;
    memset(buf,0,sizeof(buf));
    memset(buf2,0,sizeof(buf2));
    
    sockfd = socket(AF_ROUTE, SOCK_RAW, 0);
    rtm = (struct rt_msghdr *) buf;
    rtm->rtm_msglen = sizeof(struct rt_msghdr) + sizeof(struct sockaddr_in);
    rtm->rtm_version = RTM_VERSION;
    rtm->rtm_type = RTM_GET;
    rtm->rtm_addrs = RTA_DST;
    rtm->rtm_flags = RTF_LLINFO;
    rtm->rtm_pid = 1234;
    rtm->rtm_seq = SEQ;
    
    
    sin = (struct sockaddr_in *) (rtm + 1);
    sin->sin_len = sizeof(struct sockaddr_in);
    sin->sin_family = AF_INET;
    sin->sin_addr.s_addr = inet_addr(ip);
    write(sockfd, rtm, rtm->rtm_msglen);
    
    n = read(sockfd, buf2, BUFLEN);
    close(sockfd);
    
    if (n != 0) {
        int index =  sizeof(struct rt_msghdr) + sizeof(struct sockaddr_inarp) + 8;
        // savedata("test",buf2,n);
        NSString *macAddress =[NSString stringWithFormat:@"%2.2x:%2.2x:%2.2x:%2.2x:%2.2x:%2.2x",buf2[index+0], buf2[index+1], buf2[index+2], buf2[index+3], buf2[index+4], buf2[index+5]];
        //If macAddress is equal to 00:00.. then mac address not exist in ARP table and returns nil. If it retuns 08:00.. then the mac address not exist because it's not in the same subnet with the device and return nil
        if ([macAddress isEqualToString:@"00:00:00:00:00:00"] ||[macAddress isEqualToString:@"08:00:00:00:00:00"] ) {
            return nil;
        }
        return macAddress;
    }
    return nil;
}
@end

