#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <libxml/xmlreader.h>
#include <libxml/HTMLparser.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>

#define MT "santoku_html"

typedef struct {
  lua_State *L;
  char *buf;
  xmlTextReaderPtr reader;
  xmlDocPtr doc;
  bool in_attrs;
  xmlNodePtr node;
  xmlAttr *attr;
  bool empty;
  bool pending_p_open;
  bool pending_p_close;
  bool in_p;
} state_t;

// TODO: Duplicated across various libraries, need to consolidate
void callmod (lua_State *L, int nargs, int nret, const char *smod, const char *sfn)
{
  lua_getglobal(L, "require"); // arg req
  lua_pushstring(L, smod); // arg req smod
  lua_call(L, 1, 1); // arg mod
  lua_pushstring(L, sfn); // args mod sfn
  lua_gettable(L, -2); // args mod fn
  lua_remove(L, -2); // args fn
  lua_insert(L, - nargs - 1); // fn args
  lua_call(L, nargs, nret); // results
}

static state_t *peek (lua_State *L, int i)
{
  return (state_t *) luaL_checkudata(L, i, MT);
}

static int parse (lua_State *L) {
  lua_settop(L, 4);
  size_t datalen;
  const char *data = luaL_checklstring(L, 1, &datalen);
  lua_Integer sidx = luaL_optinteger(L, 2, 1);
  sidx --;
  bool is_html = lua_toboolean(L, 3);
  const char *encoding = luaL_optstring(L, 4, "utf-8");
  state_t *s = (state_t *) lua_newuserdata(L, sizeof(state_t));
  if (!s) return luaL_error(L, "memory error create xml userdata");
  luaL_getmetatable(L, MT);
  lua_setmetatable(L, -2);
  s->L = L;
  if (is_html) {
    s->doc = htmlReadDoc((const xmlChar *) data + sidx, NULL, encoding,
      HTML_PARSE_NONET | HTML_PARSE_NOERROR | HTML_PARSE_RECOVER);
    if (!s->doc) return luaL_error(L, "error opening html doc");
    s->reader = xmlReaderWalker(s->doc);
    if (!s->reader) return luaL_error(L, "error opening html reader");
  } else {
    s->doc = NULL;
    s->reader = xmlReaderForMemory(data + sidx, datalen - sidx, NULL, NULL,
      XML_PARSE_NOENT | XML_PARSE_NONET | XML_PARSE_NSCLEAN | XML_PARSE_NOERROR | XML_PARSE_RECOVER);
    if (!s->reader) return luaL_error(L, "error opening xml reader");
  }
  s->in_attrs = false;
  s->empty = false;
  s->pending_p_open = false;
  s->pending_p_close = false;
  s->in_p = false;
  return 1;
}

static int step (lua_State *L)
{
  lua_settop(L, 1);
  state_t *s = peek(L, 1);
  while (true) {
    if (s->pending_p_close) {
      s->pending_p_close = false;
      s->in_p = false;
      lua_pushstring(L, "close");
      lua_pushstring(L, "p");
      return 2;
    }
    if (s->pending_p_open) {
      s->pending_p_open = false;
      s->in_p = true;
      lua_pushstring(L, "open");
      lua_pushstring(L, "p");
      return 2;
    }
    if (s->in_attrs) {
      if (!s->attr || !s->attr->name) {
        s->in_attrs = false;
        continue;
      } else {
        lua_pushstring(L, "attribute");
        lua_pushstring(L, (char *) s->attr->name);
        if (s->attr->children) {
          xmlChar *v = xmlNodeListGetString(s->node->doc, s->attr->children, 1);
          lua_pushstring(L, (char *) v);
          xmlFree(v);
          s->attr = s->attr->next;
          return 3;
        } else {
          s->attr = s->attr->next;
          return 2;
        }
      }
    } else if (s->empty) {
      lua_pushstring(L, "close");
      s->empty = false;
      return 1;
    } else if (xmlTextReaderRead(s->reader) != 0) {
      int type = xmlTextReaderNodeType(s->reader);
      xmlChar *v;
      switch (type) {
        case XML_READER_TYPE_NONE:
          lua_pushstring(L, "error parsing, no element found");
          callmod(L, 1, 0, "santoku.error", "error");
          return 0;
        case XML_READER_TYPE_COMMENT:
          lua_pushstring(L, "comment");
          v = xmlTextReaderValue(s->reader);
          lua_pushstring(L, (char *)v);
          xmlFree(v);
          return 2;
        case XML_READER_TYPE_TEXT:
          lua_pushstring(L, "text");
          v = xmlTextReaderValue(s->reader);
          lua_pushstring(L, (char *)v);
          xmlFree(v);
          return 2;
        case XML_READER_TYPE_ELEMENT:
          xmlChar *n = xmlTextReaderName(s->reader);
          if (s->doc && (!strcmp((char *)n, "html") || !strcmp((char *)n, "head") || !strcmp((char *)n, "body"))) {
            xmlFree(n);
            continue;
          }
          lua_pushstring(L, "open");
          lua_pushstring(L, (char *)n);
          xmlFree(n);
          s->empty = xmlTextReaderIsEmptyElement(s->reader);
          s->node = xmlTextReaderCurrentNode(s->reader);
          s->attr = s->node ? s->node->properties : NULL;
          s->in_attrs = s->attr != NULL;
          return 2;
        case XML_READER_TYPE_END_ELEMENT:
          n = xmlTextReaderName(s->reader);
          if (s->doc && (!strcmp((char *)n, "html") || !strcmp((char *)n, "head") || !strcmp((char *)n, "body"))) {
            xmlFree(n);
            continue;
          }
          lua_pushstring(L, "close");
          lua_pushstring(L, (char *)n);
          xmlFree(n);
          return 2;
        default:
          continue;
      }
    } else {
      return 0;
    }
  }
}

static int destroy (lua_State *L)
{
  lua_settop(L, 1);
  state_t *s = peek(L, 1);
  if (s && s->reader)
    xmlFreeTextReader(s->reader);
  if (s && s->doc)
    xmlFreeDoc(s->doc);
  s->doc = NULL;
  s->reader = NULL;
  return 0;
}

static luaL_Reg fns[] =
{
  { "parse", parse },
  { "step", step },
  { "destroy", destroy },
  { NULL, NULL }
};

int luaopen_santoku_html_capi (lua_State *L)
{
  lua_newtable(L);
  luaL_register(L, NULL, fns);
  luaL_newmetatable(L, MT);
  lua_pushcfunction(L, destroy);
  lua_setfield(L, -2, "__gc");
  lua_pop(L, 1);
  return 1;
}
