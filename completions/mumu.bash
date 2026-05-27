# bash completion for mumu
#
# Keep in sync with src/cli.cpp (long_options) and man/mumu.1.
# Requires the 'bash-completion' package (provides _init_completion and
# _filedir). Install location: <datarootdir>/bash-completion/completions/mumu

_mumu()
{
    local cur prev words cword
    _init_completion || return

    # all options advertised to the user (the deprecated misspelled alias
    # --minimum_relative_cooccurence still works but is intentionally hidden)
    local options='
        -h --help
        -v --version
        -t --threads
        -o --otu_table
        -m --match_list
        -n --new_otu_table
        -l --log
        -a --minimum_match
        -c --minimum_ratio
        -b --minimum_ratio_type
        -d --minimum_relative_cooccurrence
        -e --legacy
    '

    case "$prev" in
        -o|--otu_table|-m|--match_list|-n|--new_otu_table|-l|--log)
            # these options expect a filename
            _filedir
            return
            ;;
        -b|--minimum_ratio_type)
            COMPREPLY=( $(compgen -W 'min avg' -- "$cur") )
            return
            ;;
        -t|--threads|-a|--minimum_match|-c|--minimum_ratio|-d|--minimum_relative_cooccurrence)
            # these options expect a numeric value: nothing to complete
            return
            ;;
    esac

    if [[ $cur == -* ]]; then
        COMPREPLY=( $(compgen -W "$options" -- "$cur") )
        return
    fi
} &&
complete -F _mumu mumu
