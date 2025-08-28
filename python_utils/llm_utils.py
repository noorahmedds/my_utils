def print_tokenized_subwords(tokenizer, token_ids):
    """
    Given a list of token ids, decode them one by one and print as sub-words
    separated by '|'.
    """
    subwords = [tokenizer.decode([tid]) for tid in token_ids]
    print(" | ".join(subwords))
    return subwords