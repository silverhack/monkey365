# Tests for psmarkdig PowerShell module
# PSScriptAnalyzer - ignore test file

Describe 'Convert-MarkDownToHtml' {
    It 'Converts simple markdown to HTML' {
        $markdown = "# Hello World"
        $result = Convert-MarkDownToHtml -Markdown $markdown
        $result | Should -Match '<h1.*?>Hello World</h1>'
    }
    It 'Handles empty input' {
        $result = Convert-MarkDownToHtml -Markdown ""
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Convert-MarkDownToPlainText' {
    It 'Converts markdown to plain text' {
        $markdown = "# Hello *World*!"
        $result = Convert-MarkDownToPlainText -Markdown $markdown
        $result | Should -Match 'Hello World'
    }
    It 'Handles empty input' {
        $result = Convert-MarkDownToPlainText -Markdown ""
        $result | Should -BeNullOrEmpty
    }
}
