<?php
/**
 * DokuWiki Plugin gistgit (Syntax Component)
 *
 * @license GPL 2 http://www.gnu.org/licenses/gpl-2.0.html
 * @author  Gunther Pippèrr <gunther@pipperr.de>
 */

// must be run within Dokuwiki
if (!defined('DOKU_INC')) die();

class syntax_plugin_gistgit extends DokuWiki_Syntax_Plugin {
    /**
     * @return string Syntax mode type
     */
    public function getType() {
        return 'substition';
    }
    /**
     * @return string Paragraph type
     */
    public function getPType() {
        return 'block';
    }
    /**
     * @return int Sort order - Low numbers go before high numbers
     */
    public function getSort() {
        return 150;
    }

    /**
     * Connect lookup pattern to lexer.
     *
     * @param string $mode Parser mode
     */
    public function connectTo($mode) {
     	 $this->Lexer->addSpecialPattern('\[gistgit project=.+?&file=.+?\]',$mode,'plugin_gistgit');
//        $this->Lexer->addEntryPattern('<FIXME>',$mode,'plugin_gistgit');
    }

//    public function postConnect() {
//        $this->Lexer->addExitPattern('</FIXME>','plugin_gistgit');
//    }

    /**
     * Handle matches of the gistgit syntax
     *
     * @param string          $match   The match of the syntax
     * @param int             $state   The state of the handler
     * @param int             $pos     The position in the document
     * @param Doku_Handler    $handler The handler
     * @return array Data for the renderer
     */
    public function handle($match, $state, $pos, Doku_Handler $handler){
        //$data = array();
		
		$pm = preg_match_all('/\[gistgit project=(.+?)&file=(.+?)\]/', $match, $result);
        $project = $result[1][0];
        $file    = $result[2][0];
        return array($project, $file);

        //return $data;
    }

    /**
     * Render xhtml output or metadata
     *
     * @param string         $mode      Renderer mode (supported modes: xhtml)
     * @param Doku_Renderer  $renderer  The renderer
     * @param array          $data      The data from the handler() function
     * @return bool If rendering was successful.
     */
    public function render($mode, Doku_Renderer $renderer, $data) {
        if($mode != 'xhtml') return false;
		
		
		list($project, $file) = $data;

		$renderer->doc .= "<script src=\"https://gist-it.appspot.com/https://github.com/$project/blob/master/$file\"></script>";
		
		$renderer->doc .= NL;
		
        return true;
    }
}

// vim:ts=4:sw=4:et:
