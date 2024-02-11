import '../mustache.dart';

abstract class Node {
  Node(this.start, this.end, this.parentNode);

  // The offset of the start of the token in the file. Unless this is a section
  // or inverse section, then this stores the start of the content of the
  // section.
  final int start;
  final int end;
  final Node parentNode;

  void accept(Visitor visitor);
  void visitChildren(Visitor visitor) {}
}

abstract class Visitor {
  void visitText(TextNode node);
  void visitVariable(VariableNode node);
  void visitSection(SectionNode node);
  void visitPartial(PartialNode node);
}

class TextNode extends Node {
  TextNode(this.text, int start, int end, Node parentNode) : super(start, end, parentNode);

  final String text;

  @override
  String toString() => '(TextNode "$_debugText" $start $end)';

  String get _debugText {
    var t = text.replaceAll('\n', '\\n');
    return t.length < 50 ? t : t.substring(0, 48) + '...';
  }

  @override
  void accept(Visitor visitor) => visitor.visitText(this);
}

abstract class NamedNode extends Node{
  NamedNode(int start, int end, Node parentNode) : super(start, end, parentNode);
  String get name;
}

class VariableNode extends NamedNode {
  VariableNode(this.name, int start, int end, Node parentNode, {this.escape = true})
      : super(start, end, parentNode);

  final String name;
  final bool escape;

  @override
  void accept(Visitor visitor) => visitor.visitVariable(this);

  @override
  String toString() => '(VariableNode "$name" escape: $escape $start $end)';
}

class SectionNode extends NamedNode {
  SectionNode(this.name, int start, int end, this.delimiters, Node parentNode,
      {this.inverse = false})
      : contentStart = end,
        super(start, end, parentNode);

  final String name;
  final String delimiters;
  final bool inverse;
  final int contentStart;
  int contentEnd; // Set in parser when close tag is parsed.
  final List<Node> children = <Node>[];

  @override
  void accept(Visitor visitor) => visitor.visitSection(this);

  @override
  void visitChildren(Visitor visitor) {
    children.forEach((node) => node.accept(visitor));
  }

  @override
  String toString() => '(SectionNode $name inverse: $inverse $start $end)';

  LambdaOnLeaveFunction onLeave;
}

class PartialNode extends NamedNode {
  PartialNode(this.name, int start, int end, this.indent, Node parentNode) : super(start, end, parentNode);

  final String name;

  // Used to store the preceding whitespace before a partial tag, so that
  // it's content can be correctly indented.
  final String indent;

  @override
  void accept(Visitor visitor) => visitor.visitPartial(this);

  @override
  String toString() => '(PartialNode $name $start $end "$indent")';
}
