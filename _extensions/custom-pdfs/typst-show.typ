#show: custom-pdfs.with(
    $if(title)$
        title: [$title$],
    $endif$

    $if(course)$
        course: [$course$],
    $endif$

    $if(datetag)$
        datetag: [$datetag$],
    $endif$

    $if(footer)$
        footer: [$footer$],
    $endif$
)
