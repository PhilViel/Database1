
CREATE FUNCTION [dbo].[fntGENE_SplitIntoTable] 
		(@list varchar(MAX), @SplitChar varchar(2))
RETURNS @tbl TABLE (strField varchar(MAX)) 
AS
/****************************************************************************************************
Code de service		:		[fntGENE_SplitIntoTable]
Nom du service		:		Divise une chaine de charactères separées par un charactèr passé en paramètre
But					:		Convertir un liste de valeurs dans une table
Facette				:		GENE
Reférence			:		GENE

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@list						Liste des valeurs
						@SplitChar					Charactère separateur
Exemple d'appel:                
                SELECT * FROM [fntGENE_SplitIntoTable]('1,2,3,4',',')

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                        @tbl						strField									table avec les elements de la liste
                    
Historique des modifications :		
						Date						Programmeur									Description							Référence
						----------					-------------------------------------		----------------------------		---------------
						2009-03-24					D.T.										Création de la fonction           
****************************************************************************************************/
BEGIN
	DECLARE @POS int
	DECLARE @LastPos int

	SELECT @LastPos=0
	SELECT @POS=CharIndex(@SplitChar,@List)
	WHILE @Pos>0
	BEGIN
		INSERT INTO @tbl(strField) SELECT substring(@list,@lastpos ,@pos-@lastpos)
		SELECT @LastPos=@Pos+1
		
		SELECT @POS=CharIndex(@SplitChar,@List,@LastPos)
	End

	IF @LastPos>0 
		INSERT INTO @tbl(strField) SELECT substring(@list,@lastpos,(len(@list)-@LastPos)+1)
	ELSE
		IF @list is not null
			INSERT INTO @tbl (strField) VALUES (@list)				
	RETURN 
END 
