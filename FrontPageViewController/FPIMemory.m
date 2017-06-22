//
//  FPIMemory.m
//  FrontPageViewController
//
//  Created by Edward Winget on 6/19/17.
//  Copyright © 2017 junesiphone. All rights reserved.
//

#import "FPIMemory.h"
#include <mach/mach.h>
#import <mach/mach_host.h>
#include <sys/sysctl.h>

#import <objc/runtime.h>


@interface FPIMemory ()

@end

@implementation FPIMemory

/* From IS2 by Matchstic https://github.com/Matchstic/InfoStats2/blob/master/InfoStats2/IS2System.m */

+(NSUInteger)getSysInfo:(uint)typeSpecifier {
    size_t size = sizeof(int);
    int results;
    int mib[2] = {CTL_HW, typeSpecifier};
    sysctl(mib, 2, &results, &size, NULL, 0);
    return (NSUInteger) results;
}

+(int)ramDataForType:(int)type {
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        NSLog(@"Failed to fetch vm statistics");
    
    /* Stats in bytes */
    NSUInteger giga = 1024*1024;
    
    if (type == 0) {
        return (int)[self getSysInfo:HW_USERMEM] / giga;
    } else if (type == -1) {
        return (int)[self getSysInfo:HW_PHYSMEM] / giga;
    }
    
    natural_t wired = vm_stat.wire_count * (natural_t)pagesize / (1024 * 1024);
    natural_t active = vm_stat.active_count * (natural_t)pagesize / (1024 * 1024);
    natural_t inactive = vm_stat.inactive_count * (natural_t)pagesize / (1024 * 1024);
    if (type == 1) {
        return vm_stat.free_count * (natural_t)pagesize / (1024 * 1024) + inactive; // Inactive is treated as free by iOS
    } else {
        return active + wired;
    }
}
+(int)ramFree {
    return [self ramDataForType:1];
}

+(int)ramUsed {
    return [self ramDataForType:2];
}

+(int)ramAvailable {
    return [self ramDataForType:0];
}

+(int)ramPhysical {
    return [self ramDataForType:-1];
}



+(void)updateMemoryWithObserver:(FrontPageViewController *)observer{
    NSLog(@"FPI- LoadMemory!");
    
}

+(void)loadMemoryWithObserver: (FrontPageViewController *) observer{
    NSMutableDictionary *memoryInfo = [[NSMutableDictionary alloc] init];
    int free = [self ramFree];
    int used = [self ramUsed];
    int available = [self ramAvailable];
    int physical = [self ramPhysical];
    
    [memoryInfo setValue:[NSNumber numberWithInt:free] forKey:@"ramFree"];
    [memoryInfo setValue:[NSNumber numberWithInt:used] forKey:@"ramUsed"];
    [memoryInfo setValue:[NSNumber numberWithInt:available] forKey:@"ramAvailable"];
    [memoryInfo setValue:[NSNumber numberWithInt:physical] forKey:@"ramPhysical"];
    
    [observer convertDictToJSON:memoryInfo withName:@"memory"];
    [observer callJSFunction:@"loadMemory()"];
    memoryInfo = nil;
}

@end
