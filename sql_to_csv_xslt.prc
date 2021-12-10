CREATE OR REPLACE PROCEDURE sql_to_csv_xslt(p_sql       varchar2,
                                            p_filename  varchar2,
                                            p_dir       varchar2,
                                            p_DELIMITER varchar2 default ',') as
/*
  Copyright DarkAthena(darkathena@qq.com)

     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
  */
  /* author:DarkAthena
     name:query sql to a csv file  (with xslt)
     date:2021-12-10
     EMAIL:darkathena@qq.com

      example 1:
     begin
       sql_to_csv_xslt('select a,b,c from tab','demo.csv','DATA_PUMP_DIR');
       END;

     example 2:
     begin
       sql_to_csv_xslt('select a,b,c from tab','demo.csv','DATA_PUMP_DIR','|');
       END;
   */
  l_ctx            dbms_xmlgen.ctxhandle;
  l_num_rows       pls_integer;
  l_xml            xmltype;
  l_transform      xmltype;
  l_xml_stylesheet varchar2(4000);
  l_csv            clob;
begin
  l_xml_stylesheet := q'^<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
  <xsl:apply-templates select="ROWSET/ROW[1]" />
  </xsl:template>
  <xsl:template match="ROW">
  <xsl:apply-templates mode="th" />
  <xsl:apply-templates select="../ROW" mode="td" />
  </xsl:template>
  <xsl:template match="ROW/*" mode="th">
  <xsl:value-of select="local-name()" />
  <xsl:if test="position() != last()">
  <xsl:text>:1</xsl:text>
  </xsl:if>
  </xsl:template>
  <xsl:template match="ROW" mode="td">
  <xsl:text>&#xd;</xsl:text><xsl:text>&#xa;</xsl:text><xsl:apply-templates />
  </xsl:template>
  <xsl:template match="ROW/*">
  <xsl:apply-templates />
  <xsl:if test="position() != last()">
  <xsl:text>:1</xsl:text>
  </xsl:if>
  </xsl:template>
  </xsl:stylesheet>^';
  l_xml_stylesheet := replace(l_xml_stylesheet, ':1', p_DELIMITER);
  l_ctx            := dbms_xmlgen.newcontext(p_sql);
  dbms_xmlgen.setnullhandling(l_ctx, dbms_xmlgen.empty_tag);
  l_xml      := dbms_xmlgen.getxmltype(l_ctx, dbms_xmlgen.none);
  l_num_rows := dbms_xmlgen.getnumrowsprocessed(l_ctx);
  dbms_xmlgen.closecontext(l_ctx);
  if l_num_rows > 0 then
    l_transform := l_xml.transform(xmltype(l_xml_stylesheet));
  end if;
  l_csv := dbms_xmlgen.convert(l_transform.getclobval(),
                               dbms_xmlgen.entity_decode);
  dbms_lob.clob2file(cl => l_csv, flocation => p_dir, fname => p_filename);
exception
  when others then
    raise;
end;
/
