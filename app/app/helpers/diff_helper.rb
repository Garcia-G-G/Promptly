module DiffHelper
  def compute_diff(old_text, new_text)
    old_lines = old_text.to_s.split("\n")
    new_lines = new_text.to_s.split("\n")

    lcs = lcs_matrix(old_lines, new_lines)
    diff_lines = backtrack_diff(lcs, old_lines, new_lines, old_lines.length, new_lines.length)
    diff_lines.reverse
  end

  private

  def lcs_matrix(a, b)
    m = Array.new(a.length + 1) { Array.new(b.length + 1, 0) }
    a.each_with_index do |x, i|
      b.each_with_index do |y, j|
        m[i + 1][j + 1] = x == y ? m[i][j] + 1 : [ m[i + 1][j], m[i][j + 1] ].max
      end
    end
    m
  end

  def backtrack_diff(m, a, b, i, j)
    result = []
    while i > 0 || j > 0
      if i > 0 && j > 0 && a[i - 1] == b[j - 1]
        result << { type: :equal, text: a[i - 1], old_num: i, new_num: j }
        i -= 1; j -= 1
      elsif j > 0 && (i == 0 || m[i][j - 1] >= m[i - 1][j])
        result << { type: :add, text: b[j - 1], new_num: j }
        j -= 1
      else
        result << { type: :del, text: a[i - 1], old_num: i }
        i -= 1
      end
    end
    result
  end
end
