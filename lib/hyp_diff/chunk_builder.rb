module HypDiff

class ChunkBuilder

  class EqualChunk < Struct.new(:tokens)
  end

  class DiffChunk < Struct.new(:deletions, :insertions)
  end

  def self.build_chunks_for(changes)
    new.build_chunks_for(changes).chunks
  end

  attr_reader :chunks

  def initialize
    @chunks = []
  end

  def build_chunks_for(changes)
    @insertions = []
    @deletions = []
    @commons = []

    changes.each do |change|
      case change.action
      when "!" then
        apply_commons
        deletions << change.old_element.text
        insertions << change.new_element.text
      when "=" then
        apply_insertions_and_deletions
        commons << change.new_element.text
      when "+" then
        apply_commons
        insertions << change.new_element.text
      when "-" then
        apply_commons
        deletions << change.old_element.text
      else
        raise "unexpected change.action #{change.action}"
      end
    end

    apply_insertions_and_deletions
    apply_commons

    self
  end

  private

  attr_reader :insertions, :deletions, :commons

  def apply_commons
    if commons.length > 0
      @chunks << EqualChunk.new(commons)
    end
    @commons = []
  end

  def apply_insertions_and_deletions
    if deletions.length > 0 || insertions.length > 0
      @chunks << DiffChunk.new(deletions, insertions)
    end

    @insertions = []
    @deletions = []
  end
end

end
