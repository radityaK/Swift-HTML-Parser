/**@file
 * @brief Swift-HTML-Parser
 * @author _tid_
 */

/**
 * HTMLNode
 */
public class HTMLNode {
    public enum HTMLNodeType : String {
        case HTMLUnkownNode     = ""
        case HTMLHrefNode       = "href"
        case HTMLTextNode       = "text"
        case HTMLCodeNode       = "code"
        case HTMLSpanNode       = "span"
        case HTMLPNode          = "p"
        case HTMLLiNode         = "li"
        case HTMLUiNode         = "ui"
        case HTMLImageNode      = "image"
        case HTMLOlNode         = "ol"
        case HTMLStrongNode     = "strong"
        case HTMLPreNode        = "pre"
        case HTMLBlockQuoteNode = "blockquote"
    }
    
    private var doc       : htmlDocPtr
    private var node      : xmlNode?
    private let nodeType  : HTMLNodeType = HTMLNodeType.HTMLUnkownNode
    
    /**
     * 親ノード
     */
    private var parent    : HTMLNode? {
        if let p = self.node?.parent {
            return HTMLNode(doc: self.doc, node: p)
        }
        return nil
    }

    /**
    * 次ノード
    */
    private var next : HTMLNode? {
        if let n : UnsafeMutablePointer<xmlNode> = node?.next {
            if n != nil {
                return HTMLNode(doc: doc, node: n)
            }
        }
        return nil
    }

    /**
     * 子ノード
     */
    private var child     : HTMLNode? {
        if let c = node?.children {
            if c != nil {
                return HTMLNode(doc: doc, node: c)
            }
        }
        return nil
    }

    /**
     * クラス名
     */
    public var className : String {
        return getAttributeNamed("class")
    }

    /**
    * タグ名
    */
    public var tagName : String {
        if node != nil {
            return ConvXmlCharToString(self.node!.name)
        }
        return ""
    }
    
    /**
     * コンテンツ
     */
    public var contents : String {
        if node != nil {
            var n = self.node!.children
            if n != nil {
                return ConvXmlCharToString(n.memory.content)
            }
        }
        return ""
    }

    /**
     * Initializer
     * @param[in] doc xmlDoc
     */
    public init(doc: htmlDocPtr = nil) {
        self.doc  = doc
        var node = xmlDocGetRootElement(doc)
        if node != nil {
            self.node = node.memory
        }
    }
    
    private init(doc: htmlDocPtr, node: UnsafePointer<xmlNode>) {
        self.doc  = doc
        self.node = node.memory

        if let type = HTMLNodeType(rawValue: tagName) {
            nodeType = type
        }
    }

    /**
     * 属性名を取得する
     * @param[in] name 属性
     * @return 属性名
     */
    public func getAttributeNamed(name: String) -> String {
        for var attr : xmlAttrPtr = node!.properties; attr != nil; attr = attr.memory.next {
            var mem = attr.memory

            if name == ConvXmlCharToString(mem.name) {
                return ConvXmlCharToString(mem.children.memory.content)
            }
        }
        
        return ""
    }
    
    /**
     * タグ名に一致する全ての子ノードを探す
     * @param[in] tagName タグ名
     * @return 子ノードの配列
     */
    public func findChildTags(tagName: String) -> [HTMLNode] {
        var nodes : [HTMLNode] = []
        
        return findChildTags(tagName, node: self.child, retAry: &nodes)
    }
    
    private func findChildTags(tagName: String, node: HTMLNode?, inout retAry: [HTMLNode] ) -> [HTMLNode] {
        if let n = node {
            for curNode in n {
                if curNode.tagName == tagName {
                    retAry.append(curNode)
                }
            
                findChildTags(tagName, node: curNode.child, retAry: &retAry)
            }
        }
        return retAry
    }
    
    /**
     * タグ名で子ノードを探す
     * @param[in] tagName タグ名
     * @return 子ノード。見つからなければnil
     */
    public func findChildTag(tagName: String) -> HTMLNode? {
        return findChildTag(tagName, node: self)
    }

    private func findChildTag(tagName: String, node: HTMLNode?) -> HTMLNode? {
        if let nd = node {
            for curNode in nd {
                if tagName == curNode.tagName {
                    return curNode
                }
            
                if let c = curNode.child {
                    if let n = findChildTag(tagName, node: c) {
                        return n
                    }
                }
            }
        }

        return nil
    }
}

extension HTMLNode : SequenceType {
    public func generate() -> HTMLNodeGenerator {
        return HTMLNodeGenerator(node: self)
    }
}

/**
* HTMLNodeGenerator
*/
public class HTMLNodeGenerator : GeneratorType {
    private var node : HTMLNode?
    
    public init(node: HTMLNode?) {
        self.node = node
    }
    
    public func next() -> HTMLNode? {
        var temp = node
        node = node?.next
        return temp
    }
}