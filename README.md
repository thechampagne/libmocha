# libmocha

[![](https://img.shields.io/github/v/tag/thechampagne/libmocha?label=version)](https://github.com/thechampagne/libmocha/releases/latest) [![](https://img.shields.io/github/license/thechampagne/libmocha)](https://github.com/thechampagne/libmocha/blob/main/LICENSE)

A C library to parse **mocha** an elegant configuration language for both humans and machines.

### Example
```c
#include <stdio.h>
#include <mocha.h>

int main(void)
{
  const char* text = "defaults: { \
         user_id: 0 \
         start_id: user_id \
        } \
        hanna: { \
        name: 'hanna rose' \
        id: @:defaults:user_id \
        inventory: ['banana' 12.32] \
        }";
       
  mocha_object_t obj;
  if (mocha_parse(&obj, text) != MOCHA_ERROR_NONE)
  {
    return 1;
  }

  for (size_t i = 0; i < obj.fields_len; i++)
  {
    mocha_field_t field = mocha_field(&obj, i);
    printf("%s: {\n", field.name);
  
    for (size_t j = 0; j < field.value.object.fields_len; j++)
    {
      mocha_field_t field0 = mocha_field(&field.value.object, j);
      printf("%s: ", field0.name);
      if (field0.type == MOCHA_VALUE_TYPE_INTEGER64)
      {
	printf("%ld\n", field0.value.integer64);
      } else if (field0.type == MOCHA_VALUE_TYPE_FLOAT64)
      {
	printf("%f\n", field0.value.float64);
      } else if (field0.type == MOCHA_VALUE_TYPE_STRING)
      {
	printf("'%s'\n", field0.value.string);
      } else if (field0.type == MOCHA_VALUE_TYPE_ARRAY)
      {
	printf("[");
	for (size_t idx = 0; idx < field0.value.array.items_len; idx++)
	{
	  mocha_value_t value;
	  mocha_value_type_t value_type = mocha_array(&field0.value.array, &value, idx);
	  if (value_type == MOCHA_VALUE_TYPE_STRING)
	  {
	    printf("'%s' ", value.string);
	  } else if (value_type == MOCHA_VALUE_TYPE_FLOAT64)
	  {
	    printf("%f", value.float64);
	  }
	}
	printf("]\n");
      } else if (field0.type == MOCHA_VALUE_TYPE_REFERENCE)
      {
	fwrite(field0.value.reference.name, field0.value.reference.name_len, 1, stdout);
	if (field0.value.reference.child != NULL) printf(":");
	mocha_reference_t reference;
	reference.child = field0.value.reference.child;
	while (mocha_reference_next(reference.child, &reference) == 0)
	{
	  fwrite(reference.name, reference.name_len, 1, stdout);
	  if (reference.child != NULL) printf(":");
	}
	printf("\n");
      }
    }
    printf("}\n");
  }
  mocha_deinit(&obj);
}
```

### References
 - [mocha](https://github.com/hqnna/mocha)

### License

This repo is released under the [BSD-3-Clause-Clear License](https://github.com/thechampagne/libmocha/blob/main/LICENSE).
