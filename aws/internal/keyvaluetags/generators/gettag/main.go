// +build ignore

package main

import (
	"bytes"
	"go/format"
	"log"
	"os"
	"sort"
	"strings"
	"text/template"

	"github.com/d2iq-dispatch/terraform-provider-aws-spot-instance/aws/internal/keyvaluetags"
)

const filename = `get_tag_gen.go`

var serviceNames = []string{
	"dynamodb",
	"ec2",
	"ecs",
	"route53resolver",
}

type TemplateData struct {
	ServiceNames []string
}

func main() {
	// Always sort to reduce any potential generation churn
	sort.Strings(serviceNames)

	templateData := TemplateData{
		ServiceNames: serviceNames,
	}
	templateFuncMap := template.FuncMap{
		"ClientType":                        keyvaluetags.ServiceClientType,
		"ListTagsFunction":                  keyvaluetags.ServiceListTagsFunction,
		"ListTagsInputFilterIdentifierName": keyvaluetags.ServiceListTagsInputFilterIdentifierName,
		"ListTagsInputResourceTypeField":    keyvaluetags.ServiceListTagsInputResourceTypeField,
		"ListTagsOutputTagsField":           keyvaluetags.ServiceListTagsOutputTagsField,
		"TagPackage":                        keyvaluetags.ServiceTagPackage,
		"Title":                             strings.Title,
	}

	tmpl, err := template.New("gettag").Funcs(templateFuncMap).Parse(templateBody)

	if err != nil {
		log.Fatalf("error parsing template: %s", err)
	}

	var buffer bytes.Buffer
	err = tmpl.Execute(&buffer, templateData)

	if err != nil {
		log.Fatalf("error executing template: %s", err)
	}

	generatedFileContents, err := format.Source(buffer.Bytes())

	if err != nil {
		log.Fatalf("error formatting generated file: %s", err)
	}

	f, err := os.Create(filename)

	if err != nil {
		log.Fatalf("error creating file (%s): %s", filename, err)
	}

	defer f.Close()

	_, err = f.Write(generatedFileContents)

	if err != nil {
		log.Fatalf("error writing to file (%s): %s", filename, err)
	}
}

var templateBody = `
// Code generated by generators/gettag/main.go; DO NOT EDIT.

package keyvaluetags

import (
	"github.com/aws/aws-sdk-go/aws"
{{- range .ServiceNames }}
	"github.com/aws/aws-sdk-go/service/{{ . }}"
{{- end }}
)

{{- range .ServiceNames }}

// {{ . | Title }}GetTag fetches an individual {{ . }} service tag for a resource.
// Returns whether the key exists, the key value, and any errors.
// This function will optimise the handling over {{ . | Title }}ListTags, if possible.
// The identifier is typically the Amazon Resource Name (ARN), although
// it may also be a different identifier depending on the service.
func {{ . | Title }}GetTag(conn {{ . | ClientType }}, identifier string{{ if . | ListTagsInputResourceTypeField }}, resourceType string{{ end }}, key string) (bool, *string, error) {
	{{- if . | ListTagsInputFilterIdentifierName }}
	input := &{{ . | TagPackage  }}.{{ . | ListTagsFunction }}Input{
		Filters: []*{{ . | TagPackage  }}.Filter{
			{
				Name:   aws.String("{{ . | ListTagsInputFilterIdentifierName }}"),
				Values: []*string{aws.String(identifier)},
			},
			{
				Name:   aws.String("key"),
				Values: []*string{aws.String(key)},
			},
		},
	}

	output, err := conn.{{ . | ListTagsFunction }}(input)

	if err != nil {
		return false, nil, err
	}

	listTags := {{ . | Title }}KeyValueTags(output.{{ . | ListTagsOutputTagsField }})
	{{- else }}
	listTags, err := {{ . | Title }}ListTags(conn, identifier{{ if . | ListTagsInputResourceTypeField }}, resourceType{{ end }})

	if err != nil {
		return false, nil, err
	}
	{{- end }}

	return listTags.KeyExists(key), listTags.KeyValue(key), nil
}
{{- end }}
`
