
import { preprocess } from 'svelte/compiler'

/**
 * @typedef {import("svelte/types/compiler/preprocess").PreprocessorGroup} PreprocessorGroup
 * @param {PreprocessorGroup[]} preprocessors
 * @returns {PreprocessorGroup[]}
 */
export function sequence(preprocessors) {
  return preprocessors.map((preprocessor) => ({
    markup({ content, filename }) {
      return preprocess(content, preprocessor, { filename })
    },
  }))
}