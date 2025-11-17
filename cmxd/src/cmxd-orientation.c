/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Device Orientation Detection Implementation
 * 
 * Implements accelerometer-based orientation detection with tablet mode
 * awareness and dual-sensor support. Provides platform-independent 
 * orientation mapping and stability protection.
 * 
 * Copyright (c) 2025 Armando DiCianno <armando@noonshy.com>
 */

#include "cmxd-orientation.h"
#include "cmxd-calculations.h"
#include "cmxd-protocol.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdarg.h>

/*
 * =============================================================================
 * MODULE STATE AND CONFIGURATION
 * =============================================================================
 */

/* Module state */
static const char* last_known_orientation = CMXD_PROTOCOL_ORIENTATION_NORMAL;
static bool verbose_logging = false;

/* Logging function (set by main application) */
static void (*log_debug_func)(const char *fmt, ...) = NULL;

/*
 * =============================================================================
 * LOGGING AND INITIALIZATION
 * =============================================================================
 */

/* Set the debug logging function */
void cmxd_orientation_set_log_debug(void (*func)(const char *fmt, ...))
{
    log_debug_func = func;
}

/* Initialize orientation detection module */
void cmxd_orientation_init(void)
{
    last_known_orientation = CMXD_PROTOCOL_ORIENTATION_NORMAL;
    verbose_logging = true;  /* Enable verbose logging for tablet protection */
}

/*
 * =============================================================================
 * CORE ORIENTATION DETECTION
 * =============================================================================
 */

/* Determine raw device orientation based on accelerometer readings */
int cmxd_get_device_orientation(double x, double y, double z)
{
    double abs_x = fabs(x);
    double abs_y = fabs(y);
    double abs_z = fabs(z);
    
    /* Find the axis with the largest magnitude (closest to gravity) */
    if (abs_z > abs_x && abs_z > abs_y) {
        return (z > 0) ? CMXD_DEVICE_Z_UP : CMXD_DEVICE_Z_DOWN;
    } else if (abs_y > abs_x) {
        return (y > 0) ? CMXD_DEVICE_Y_UP : CMXD_DEVICE_Y_DOWN;
    } else {
        return (x > 0) ? CMXD_DEVICE_X_UP : CMXD_DEVICE_X_DOWN;
    }
}

/*
 * =============================================================================
 * PLATFORM ORIENTATION MAPPING
 * =============================================================================
 */

/* Map device orientation to standard platform terms */
const char* cmxd_get_platform_orientation(int orientation_code)
{
    switch (orientation_code) {
        case CMXD_DEVICE_X_DOWN:  /* X-down - normal laptop position */
            return CMXD_PROTOCOL_ORIENTATION_NORMAL;
        case CMXD_DEVICE_X_UP:    /* X-up - laptop upside down */
            return CMXD_PROTOCOL_ORIENTATION_BOTTOM_UP;
        case CMXD_DEVICE_Y_UP:    /* Y-up - laptop standing vertically (right side up) */
            return CMXD_PROTOCOL_ORIENTATION_RIGHT_UP;
        case CMXD_DEVICE_Y_DOWN:  /* Y-down - laptop standing vertically (left side up) */
            return CMXD_PROTOCOL_ORIENTATION_LEFT_UP;
        case CMXD_DEVICE_Z_UP:    /* Z-up - unusual orientation, default to normal */
        case CMXD_DEVICE_Z_DOWN:  /* Z-down - unusual orientation, default to normal */
        default:
            return CMXD_PROTOCOL_ORIENTATION_NORMAL;  /* Default to normal for edge cases */
    }
}

/* Simple orientation detection without tablet protection */
const char* cmxd_get_orientation_simple(double x, double y, double z)
{
    int orientation = cmxd_get_device_orientation(x, y, z);
    const char* orientation_name = cmxd_get_platform_orientation(orientation);
    
    /* Orientation debug output reduced for cleaner format */
    
    return orientation_name;
}

/* Get orientation with tablet mode reading protection */
/* Prevents orientation changes FROM vertical orientations (right-up/left-up) in tablet mode when tilted > 45° for reading stability */
/* Also implements general tilt protection to prevent orientation bouncing during device transitions */
const char* cmxd_get_orientation_with_tablet_protection(double x, double y, double z, const char* current_mode)
{
    /* Calculate current orientation first */
    int orientation = cmxd_get_device_orientation(x, y, z);
    const char* orientation_name = cmxd_get_platform_orientation(orientation);
    
    /* Calculate tilt angle for tablet mode protection */
    double tilt_angle = cmxd_calculate_tilt_angle(x, y, z);
    
    /* Option 3: Tilt-based orientation lock for tablet mode
     * When in tablet mode and starting in a vertical orientation (right-up/left-up), if tilt goes below 45° (lying flat),
     * lock orientation until it comes back above 45° to prevent unwanted switches to normal */
    if (current_mode && strcmp(current_mode, CMXD_PROTOCOL_MODE_TABLET) == 0 && 
        last_known_orientation != NULL && 
        (strcmp(last_known_orientation, CMXD_PROTOCOL_ORIENTATION_RIGHT_UP) == 0 || 
         strcmp(last_known_orientation, CMXD_PROTOCOL_ORIENTATION_LEFT_UP) == 0) &&  /* Currently in vertical orientations (right-up/left-up) */
        tilt_angle < 45.0 &&  /* Tilted flat (lying on table) */
        (strcmp(orientation_name, CMXD_PROTOCOL_ORIENTATION_NORMAL) == 0 || 
         strcmp(orientation_name, CMXD_PROTOCOL_ORIENTATION_BOTTOM_UP) == 0)) {         /* Trying to switch to normal/bottom-up */
        
        /* Tablet tilt lock debug output reduced */
        return last_known_orientation;
    }
    
    /* Normal orientation detection - update last known orientation */
    last_known_orientation = orientation_name;
    
    /* Normal orientation debug output reduced */
    return orientation_name;
}

/* Get orientation with dual-sensor switching (enhanced for mode-specific protection) */
/* Uses actual device mode to switch between sensors and apply mode-specific orientation locking */
const char* cmxd_get_orientation_with_sensor_switching(double lid_x, double lid_y, double lid_z,
                                                      double base_x, double base_y, double base_z,
                                                      const char* current_mode)
{    
    const char* orientation_name;
    
    /* Mode-specific orientation handling */
    if (current_mode && strcmp(current_mode, CMXD_PROTOCOL_MODE_LAPTOP) == 0) {
        /* Laptop mode: ALWAYS normal - ignore device rotation */
        return CMXD_PROTOCOL_ORIENTATION_NORMAL;
        
    } else if (current_mode && (strcmp(current_mode, CMXD_PROTOCOL_MODE_TABLET) == 0 || strcmp(current_mode, CMXD_PROTOCOL_MODE_TENT) == 0)) {
        /* Tablet/Tent mode: Use base sensor with tablet protection */
        orientation_name = cmxd_get_orientation_with_tablet_protection(base_x, base_y, base_z, current_mode);
        
    } else {
        /* Flat mode: Allow natural orientation detection using lid sensor */
        orientation_name = cmxd_get_orientation_simple(lid_x, lid_y, lid_z);
    }
    
    return orientation_name;
}

/* Set verbose logging for orientation detection */
void cmxd_orientation_set_verbose(bool verbose)
{
    verbose_logging = verbose;
}