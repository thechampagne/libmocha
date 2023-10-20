/*
 * The Clear BSD License
 * 
 * Copyright (c) 2023 XXIV
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted (subject to the limitations in the disclaimer
 * below) provided that the following conditions are met:
 * 
 *      * Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * 
 *      * Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 * 
 *      * Neither the name of the copyright holder nor the names of its
 *      contributors may be used to endorse or promote products derived from this
 *      software without specific prior written permission.
 * 
 * NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY
 * THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
#ifndef __MOCHA_H__
#define __MOCHA_H__

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    MOCHA_ERROR_NONE,
    MOCHA_ERROR_MISSING_FIELD,
    MOCHA_ERROR_DUPLICATE_FIELD,
    MOCHA_ERROR_ROOT_REFERENCE,
    MOCHA_ERROR_OUT_OF_MEMORY,
    MOCHA_ERROR_INVALID_CHARACTER,
    MOCHA_ERROR_OVERFLOW,
    MOCHA_ERROR_END_OF_STREAM,
    MOCHA_ERROR_UNEXPECTED_TOKEN,
    MOCHA_ERROR_UNEXPECTED_CHARACTER
} mocha_error_t;

typedef enum {
    MOCHA_VALUE_TYPE_NIL,
    MOCHA_VALUE_TYPE_STRING,
    MOCHA_VALUE_TYPE_REFERENCE,
    MOCHA_VALUE_TYPE_BOOLEAN,
    MOCHA_VALUE_TYPE_OBJECT,
    MOCHA_VALUE_TYPE_ARRAY,
    MOCHA_VALUE_TYPE_FLOAT64,
    MOCHA_VALUE_TYPE_INTEGER64
} mocha_value_type_t;

typedef struct {
  const char* name;
  size_t name_len;
  const void* child;
  size_t index;
} mocha_reference_t;

typedef struct {
  void* items;
  size_t items_len;
} mocha_array_t;

typedef struct {
  void* fields;
  size_t fields_len;
} mocha_object_t;

typedef union {
  const char* string;
  mocha_reference_t reference;
  int boolean;
  mocha_object_t object;
  mocha_array_t array;
  double float64;
  int64_t integer64;
} mocha_value_t;

typedef struct {
  const char* name;
  mocha_value_t value;
  mocha_value_type_t type;
} mocha_field_t;

extern mocha_error_t mocha_parse(mocha_object_t* object, const char* src);

extern void mocha_deinit(mocha_object_t* object);

extern mocha_field_t mocha_field(const mocha_object_t* object, size_t index);

extern mocha_value_type_t mocha_array(const mocha_array_t* array, mocha_value_t* value, size_t index);

extern int mocha_reference_next(mocha_reference_t* reference);

#ifdef __cplusplus
}
#endif

#endif // __MOCHA_H__
