//nolint:wrapcheck
package cmd

import (
	"bytes"
	"errors"
	"io/fs"
	"log"
	"os"
	"strings"

	"github.com/olekukonko/tablewriter"
	"github.com/spf13/cobra"

	"github.com/open-policy-agent/opa/ast"
	"github.com/open-policy-agent/opa/loader"

	"github.com/styrainc/regal/internal/compile"
)

type tableCommandParams struct {
	writeToReadme bool
}

func init() {
	params := tableCommandParams{}
	parseCommand := &cobra.Command{
		Hidden: true,
		Use:    "table <path> [path [...]]",
		Long:   "Create a markdown table from rule annotations found in provided modules",

		PreRunE: func(_ *cobra.Command, args []string) error {
			if len(args) == 0 {
				return errors.New("no files to parse for annotations provided")
			}

			return nil
		},

		Run: func(_ *cobra.Command, args []string) {
			if err := createTable(args, params); err != nil {
				log.SetOutput(os.Stderr)
				log.Println(err)
				os.Exit(1)
			}
		},
	}
	parseCommand.Flags().BoolVar(&params.writeToReadme, "write-to-readme", false, "Write table to README.md")
	RootCommand.AddCommand(parseCommand)
}

func createTable(args []string, params tableCommandParams) error {
	result, err := loader.NewFileLoader().Filtered(args, func(abspath string, info fs.FileInfo, depth int) bool {
		return strings.HasSuffix(abspath, "_test.rego")
	})
	if err != nil {
		return err
	}

	modules := map[string]*ast.Module{}

	for path, file := range result.Modules {
		modules[path] = file.Parsed
	}

	compiler := compile.NewCompilerWithRegalBuiltins()
	compiler.Compile(modules)

	if compiler.Failed() {
		return compiler.Errors
	}

	as := compiler.GetAnnotationSet()
	flattened := as.Flatten()

	tableData := make([][]string, 0, len(flattened))

	traversedTitles := map[string]struct{}{}

	for _, entry := range flattened {
		annotations := entry.Annotations

		_, ok := annotations.Custom["category"]
		if !ok {
			continue
		}

		if _, ok = traversedTitles[annotations.Title]; ok {
			continue
		}

		traversedTitles[annotations.Title] = struct{}{}

		//nolint:forcetypeassert
		tableData = append(tableData, []string{
			annotations.Custom["category"].(string),
			"[" + annotations.Title + "](" + annotations.RelatedResources[0].Ref.String() + ")",
			annotations.Description,
		})
	}

	return writeTable(tableData, params)
}

func writeTable(tableData [][]string, params tableCommandParams) error {
	var buf bytes.Buffer

	table := tablewriter.NewWriter(&buf)
	table.SetHeader([]string{"Category", "Title", "Description"})
	table.SetAutoFormatHeaders(false)
	table.SetBorders(tablewriter.Border{Left: true, Top: false, Right: true, Bottom: false})
	table.SetCenterSeparator("|")
	table.SetAutoWrapText(false)
	table.AppendBulk(tableData)
	table.Render()

	if !params.writeToReadme {
		_, err := os.Stdout.Write(buf.Bytes())

		return err
	}

	file, err := os.ReadFile("README.md")
	if err != nil {
		return err
	}

	first := strings.Split(string(file), "<!-- RULES_TABLE_START -->")[0]
	last := strings.Split(string(file), "<!-- RULES_TABLE_END -->")[1]

	newReadme := first + "<!-- RULES_TABLE_START -->\n\n" + buf.String() + "\n<!-- RULES_TABLE_END -->" + last

	return os.WriteFile("README.md", []byte(newReadme), 0o600)
}