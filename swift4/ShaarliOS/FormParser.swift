//
//  FormParser.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import Foundation

// internal helper uses libxml2 graceful html parsing
func findForms(_ body:Data?, _ encoding:String?) -> [String : [String : String]] {
    guard let da = body
        else { return [:] }
    return FormParser().parse(da)
}

private class FormParser {

    private var forms : [String:[String:String]] = [:]
    private var form : [String:String] = [:]
    private var formName = ""

    func parse(_ data:Data) -> [String:[String:String]] {
        var sax = htmlSAXHandler()
        sax.initialized = XML_SAX2_MAGIC
        sax.startElement = startElementSAX // could this be closures?
        sax.endElement = endElementSAX
        sax.characters = charactersFoundSAX
        // handler.error = errorEncounteredSAX
        
        // https://curl.haxx.se/libcurl/c/htmltitle.html
        // http://xmlsoft.org/html/libxml-HTMLparser.html#htmlParseChunk
        // https://stackoverflow.com/questions/41140050/parsing-large-xml-from-server-while-downloading-with-libxml2-in-swift-3
        // https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/XMLParser.swift#L524
        // http://redqueencoder.com/wrapping-libxml2-for-swift/ bzw. https://github.com/SonoPlot/Swift-libxml
        let ctxt = htmlCreatePushParserCtxt(&sax, Unmanaged.passUnretained(self).toOpaque(), "", 0, "", XML_CHAR_ENCODING_NONE)
        defer { xmlFreeParserCtxt(ctxt) }
        
        let _ = data.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> Int32 in
            return htmlParseChunk(ctxt, bytes, Int32(data.count), 0)
        }
        htmlParseChunk(ctxt, "", 0, 1)
        
        return forms
    }
    
    func startElement(_ name: UnsafePointer<xmlChar>? , _ atts:UnsafePointer<UnsafePointer<xmlChar>?>?) {
        let n = decode(name)
        switch n {
        case "form":
            formName = nameAndValue(atts).0
            form = [:]
        case "input":
            let nv = nameAndValue(atts)
            form[nv.0] = nv.1
        default:
            break
        }
    }
    
    func endElement(_ name:UnsafePointer<xmlChar>?) {
        let n = decode(name)
        switch n {
        case "form":
            forms[formName] = form
            formName = ""
        default:
            break
        }
    }
    
    func charactersFound(_ ch: UnsafePointer<xmlChar>?, _ len: CInt) {
        
    }

    // https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/XMLParser.swift#L33
    func decode(_ bytes:UnsafePointer<xmlChar>?) -> String? {
        guard let bytes = bytes
            else { return nil }
        if let (str, _) = String.decodeCString(bytes, as: UTF8.self, repairingInvalidCodeUnits: false) {
            return str
        }
        return nil
    }

    // iterate over the attributes and pull out name and value attribute values
    func nameAndValue(_ atts: UnsafePointer<UnsafePointer<xmlChar>?>?) -> (name: String, value: String) {
        guard let atts = atts
            else { return ("","") }
        var name = ""
        var valu = ""
        
        var i = 0
        while (atts[i] != nil) {
            let n = decode(atts[i])!
            let v = decode(atts[i+1])!
            i+=2
            switch n {
            case "id":
                if name == "" {
                    name = v
                }
            case "name":
                name = v
            case "value":
                valu = v
            default:
                break
            }
        }

        return (name, valu)
    }
}

private func startElementSAX(_ ctx: UnsafeMutableRawPointer?,
                             _ name: UnsafePointer<xmlChar>?,
                             _ attributes: UnsafeMutablePointer<UnsafePointer<xmlChar>?>?) {
    let parser = Unmanaged<FormParser>.fromOpaque(ctx!).takeUnretainedValue()
    parser.startElement(name, attributes)
}

private func endElementSAX(_ ctx: UnsafeMutableRawPointer?, name: UnsafePointer<xmlChar>?) {
    let parser = Unmanaged<FormParser>.fromOpaque(ctx!).takeUnretainedValue()
    parser.endElement(name)
}

private func charactersFoundSAX(_ ctx: UnsafeMutableRawPointer?, ch: UnsafePointer<xmlChar>?, len: CInt) {
    let parser = Unmanaged<FormParser>.fromOpaque(ctx!).takeUnretainedValue()
    parser.charactersFound(ch, len)
}