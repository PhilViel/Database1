/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntGENE_ObtenirElementsAdresse
Nom du service		: Obtenir les éléments séparés d’une adresse
But 				: Décortiquer les éléments d’une adresse comme le numéro civique, la rue et le numéro
					  d’appartement à partir d’une adresse complète.
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcAdresse					Une adresse.  Exemple: "586 rue Lajoie app. 5"
						bSeparer_Type_Rue			Indicateur de séparation du type de rue de l'adresse.  S'il est
													absent, on considère qu'il doit y avoir séparation du type de rue.

Exemple d’appel		:	select * from [dbo].[fntGENE_ObtenirElementsAdresse]('586 rue Lajoie app. 5 CP 10 RR 5',0)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							vcNo_Civique					Numéro civique de l’adresse.
						S/O							vcRue							Rue de l’adresse.
						S/O							vcNo_Appartement				Numéro de l’appartement de l’adresse.
						S/O							vcType_Rue						Type de rue.
						S/O							vcCase_Postale					Numéro de case ou boîte postale.
						S/O							vcRoute_Rurale					Numéro de route rurale

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-05-27		Éric Deshaies					Création du service
		2009-02-05		Éric Deshaies					Transformer la fonction scalar en fonction
																	table.	Trimmer les valeurs de retour pour
																	éviter un erreur.
		2012-01-12		Éric Deshaies					Tenir compte qu'il y a un nouveau format
																	dans les données des adresses.  Le numéro
																	d'appartement peut maintenant être au début
																	de l'adresse sous la forme 5-586 Rue Lajoie.
																	Extraire le type de rue et la case postale
																	afin de permettre l'affichage des adresses
																	en cours dans le Portail client.
		2012-02-08		Éric Deshaies					Extraire le numéro de route rurale.
		2014-04-02		Pierre-Luc Simard			Extraire le numéro de route rurale, 
																	même si le type de rue n'est pas demandé.

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_ObtenirElementsAdresse]
(
	@vcAdresse VARCHAR(75),
	@bSeparer_Type_Rue BIT
)
RETURNS @tblGENE_Adresse TABLE
(
	vcNo_Civique VARCHAR(10) NULL,
	vcRue VARCHAR(75) NULL,
	vcNo_Appartement VARCHAR(10) NULL,
	vcType_Rue VARCHAR(20) NULL,
	vcCase_Postale VARCHAR(10) NULL,
	vcRoute_Rurale VARCHAR(10) NULL
)
AS
BEGIN
	IF @vcAdresse IS NULL OR
	   LTRIM(RTRIM(@vcAdresse)) = ''
		BEGIN
			INSERT @tblGENE_Adresse (vcNo_Civique)
							 VALUES (NULL)
			RETURN
		END

	DECLARE
		@vcTMP VARCHAR(75),
		@vcChaine VARCHAR(75),
		@iPosDebut INT,
		@iPosDebutElement INT,
		@iLongueur1 INT,
		@vcNoApp VARCHAR(25),
		@iCompteur INT,
		@vcNo_Civique VARCHAR(25),
		@vcRue VARCHAR(75),
		@iPosTiret INT,
		@vcType_Rue VARCHAR(20),
		@vcCase_Postale VARCHAR(10),
		@vcRoute_Rurale VARCHAR(10),
		@vcListeTypeRue VARCHAR(1000),
		@vcListeCasePostale VARCHAR(500),
		@vcListePrefixe VARCHAR(500),
		@vcElementRecherche VARCHAR(20),
		@vcElementCorrige VARCHAR(20),
		@iAPP_APT INT,
		@bCarNum BIT,
		@bMot BIT

	IF @bSeparer_Type_Rue IS NULL
		SET @bSeparer_Type_Rue = 1


	------------------------------------------------------------------------
	-- Ménage au début et à la fin de l'adresse, enlever les doubles espaces
	------------------------------------------------------------------------
	SET @vcAdresse = LTRIM(RTRIM(@vcAdresse))

	WHILE LEN(@vcAdresse) > 0 AND SUBSTRING(@vcAdresse,1,1) IN (' ','-',',','.',':',';')
		SET @vcAdresse = SUBSTRING(@vcAdresse,2,75)

	WHILE LEN(@vcAdresse) > 0 AND SUBSTRING(@vcAdresse,LEN(@vcAdresse),1) IN (' ','-',',','.',':',';','#')
		SET @vcAdresse = SUBSTRING(@vcAdresse,1,LEN(@vcAdresse)-1)

	WHILE CHARINDEX('  ',@vcAdresse) > 0
		SET @vcAdresse = REPLACE(@vcAdresse,'  ',' ')

	WHILE CHARINDEX(' , ',@vcAdresse) > 0
		SET @vcAdresse = REPLACE(@vcAdresse,' , ',', ')
		
	WHILE CHARINDEX(' - ',@vcAdresse) > 0
		SET @vcAdresse = REPLACE(@vcAdresse,' - ','-')


	-------------------------------------------------------
	-- Déterminer et extraire le casier postal de l'adresse
	-------------------------------------------------------

	-- Inventaire des préfixes à rechercher
	-- Note importante: Mettre les préfixes en ordre inverse de grandeur
	SET @vcListeCasePostale = 'PO Box Box Office|Casier postale|Boîte Postale|Boite postale|Casier postal|Case postale|Boite postal|Case postal|Boite poste|P. O. Box'+
							  '|P.O. Box|Mail Box|Post Box|P O Box|P.O Box|P.O.Box|P.O.B.|PO Box|Boite|Boîte|Box #|B. P.|C. P.|C.P..|C.P.|B.P.|CP.|Box|Bte|CP|'
	SET @vcCase_Postale = NULL															

	-- Rouler les préfixes à rechercher
	WHILE LEN(@vcListeCasePostale) > 1 AND
		  LEN(@vcAdresse) > 0 AND 
		  @vcCase_Postale IS NULL
		BEGIN
			-- Rechercher un préfixe
			SET @vcElementRecherche = UPPER(SUBSTRING(@vcListeCasePostale,1,CHARINDEX('|',@vcListeCasePostale)-1))
			SET @iPosDebut = CHARINDEX(@vcElementRecherche,UPPER(@vcAdresse))

			-- Le préfixe est présent et il est suivi d'un caractère significatif indiquant qu'il y a un numéro de case et est
			-- précédé d'un caractère séparateur pour que les caractères recherché fasse un mot complet et ne soit pas qu'une partie d'un autre mot
			IF @iPosDebut > 0 AND 
			   ((@iPosDebut = 1 AND LEN(@vcAdresse) > LEN(@vcElementRecherche) AND SUBSTRING(@vcAdresse,LEN(@vcElementRecherche)+1,1) IN (' ',',',':',';','0','1','2','3','4','5','6','7','8','9')) OR
				(@iPosDebut > 1 AND SUBSTRING(@vcAdresse,@iPosDebut-1,1) IN (' ',',',':',';') AND
					 (@iPosDebut+LEN(@vcElementRecherche) > LEN(@vcAdresse) OR SUBSTRING(@vcAdresse,@iPosDebut+LEN(@vcElementRecherche),1) IN (' ',',',':',';','0','1','2','3','4','5','6','7','8','9'))))
				BEGIN
					-- Trouver le début du casier postal
					SET @iLongueur1 = LEN(@vcElementRecherche)
					SET @iCompteur = 0
					WHILE @iPosDebut+@iLongueur1+@iCompteur <= LEN(@vcAdresse) AND
						  SUBSTRING(@vcAdresse,@iPosDebut+@iLongueur1+@iCompteur,1) IN (' ','.',',',':',';')
						SET @iCompteur = @iCompteur + 1
					SET @iPosDebutElement = @iPosDebut + @iLongueur1 + @iCompteur
					SET @iLongueur1 = @iLongueur1 + @iCompteur
					
					-- Trouver la fin du casier postal
					SET @iCompteur = 0
					WHILE @iPosDebutElement+@iCompteur <= LEN(@vcAdresse) AND
						  SUBSTRING(@vcAdresse,@iPosDebutElement+@iCompteur,1) NOT IN (' ','.',',',':',';','-')
						SET @iCompteur = @iCompteur + 1

					-- Retenir le numéro du casier postal
					SET @vcCase_Postale = SUBSTRING(@vcAdresse,@iPosDebutElement,@iCompteur)

					-- Ménage au début et à la fin du casier postal
					WHILE LEN(@vcCase_Postale) > 0 AND SUBSTRING(@vcCase_Postale,1,1) IN (' ','-',',','.',':',';')
						SET @vcCase_Postale = SUBSTRING(@vcCase_Postale,2,75)

					WHILE LEN(@vcCase_Postale) > 0 AND SUBSTRING(@vcCase_Postale,LEN(@vcCase_Postale),1) IN (' ','-',',','.',':',';')
						SET @vcCase_Postale = SUBSTRING(@vcCase_Postale,1,LEN(@vcCase_Postale)-1)

					-- Extraire de l'adresse tout le texte du casier postal
					SET @vcTMP = ''
					IF @iPosDebut > 1
						SET @vcTMP = @vcTMP + SUBSTRING(@vcAdresse,1,@iPosDebut-1)
					IF @iPosDebut+@iLongueur1+@iCompteur <= LEN(@vcAdresse)
						SET @vcTMP = @vcTMP + SUBSTRING(@vcAdresse,@iPosDebut+@iLongueur1+@iCompteur,75)
					SET @vcAdresse = @vcTMP

					-- Ménage au début et à la fin de l'adresse
					SET @vcAdresse = LTRIM(RTRIM(@vcAdresse))

					WHILE LEN(@vcAdresse) > 0 AND SUBSTRING(@vcAdresse,1,1) IN (' ','-',',','.',':',';')
						SET @vcAdresse = SUBSTRING(@vcAdresse,2,75)

					WHILE LEN(@vcAdresse) > 0 AND SUBSTRING(@vcAdresse,LEN(@vcAdresse),1) IN (' ','-',',','.',':',';')
						SET @vcAdresse = SUBSTRING(@vcAdresse,1,LEN(@vcAdresse)-1)

					-- S'il n'y a pas de case postale, s'assurer de retourner NULL
					IF LTRIM(RTRIM(@vcCase_Postale)) = ''
						SET @vcCase_Postale = NULL
				END
			-- Le préfixe est absent, retirer de l'inventaire des préfixes pour rechercher le suivant
			ELSE
				SET @vcListeCasePostale = SUBSTRING(@vcListeCasePostale,CHARINDEX('|',@vcListeCasePostale)+1,500)
		END


	-----------------------------------------
	-- Déterminer et extraire la route rurale
	-----------------------------------------
	SET @vcRoute_Rurale = NULL

	IF @bSeparer_Type_Rue = 0
		BEGIN
			-- Inventaire des préfixes à rechercher
			-- Note importante: Mettre les préfixes en ordre inverse de grandeur
			SET @vcListeCasePostale = 'Route rurale|R. R. #|R.R. #|R. R.|R.R.#|R.R #|R.R.|R.R#|RR #|R.R|RR.|RR |RR|'

			-- Rouler les préfixes à rechercher
			WHILE LEN(@vcListeCasePostale) > 1 AND
				  LEN(@vcAdresse) > 0 AND 
				  @vcRoute_Rurale IS NULL
				BEGIN
					-- Rechercher un préfixe
					SET @vcElementRecherche = UPPER(SUBSTRING(@vcListeCasePostale,1,CHARINDEX('|',@vcListeCasePostale)-1))
					SET @iPosDebut = CHARINDEX(@vcElementRecherche,UPPER(@vcAdresse))

					-- Le préfixe est présent et il est suivi d'un caractère significatif indiquant qu'il y a un numéro de route rurale et est
					-- précédé d'un caractère séparateur pour que les caractères recherché fasse un mot complet et ne soit pas qu'une partie d'un autre mot
					IF @iPosDebut > 0 AND 
					   ((@iPosDebut = 1 AND LEN(@vcAdresse) > LEN(@vcElementRecherche) AND SUBSTRING(@vcAdresse,LEN(@vcElementRecherche)+1,1) IN (' ',',',':',';','0','1','2','3','4','5','6','7','8','9')) OR
						(@iPosDebut > 1 AND SUBSTRING(@vcAdresse,@iPosDebut-1,1) IN (' ',',',':',';') AND
							 (@iPosDebut+LEN(@vcElementRecherche) > LEN(@vcAdresse) OR SUBSTRING(@vcAdresse,@iPosDebut+LEN(@vcElementRecherche),1) IN (' ',',',':',';','0','1','2','3','4','5','6','7','8','9'))))
						BEGIN
							-- Trouver le début de la route rurale
							SET @iLongueur1 = LEN(@vcElementRecherche)
							SET @iCompteur = 0
							WHILE @iPosDebut+@iLongueur1+@iCompteur <= LEN(@vcAdresse) AND
								  SUBSTRING(@vcAdresse,@iPosDebut+@iLongueur1+@iCompteur,1) IN (' ','.',',',':',';')
								SET @iCompteur = @iCompteur + 1
							SET @iPosDebutElement = @iPosDebut + @iLongueur1 + @iCompteur
							SET @iLongueur1 = @iLongueur1 + @iCompteur
							
							-- Trouver la fin de la route rurale
							SET @iCompteur = 0
							WHILE @iPosDebutElement+@iCompteur <= LEN(@vcAdresse) AND
								  SUBSTRING(@vcAdresse,@iPosDebutElement+@iCompteur,1) NOT IN (' ','.',',',':',';','-')
								SET @iCompteur = @iCompteur + 1

							-- Retenir le numéro de la route rurale
							SET @vcRoute_Rurale = SUBSTRING(@vcAdresse,@iPosDebutElement,@iCompteur)

							-- Ménage au début et à la fin de la route rurale
							WHILE LEN(@vcRoute_Rurale) > 0 AND SUBSTRING(@vcRoute_Rurale,1,1) IN (' ','-',',','.',':',';')
								SET @vcRoute_Rurale = SUBSTRING(@vcRoute_Rurale,2,75)

							WHILE LEN(@vcRoute_Rurale) > 0 AND SUBSTRING(@vcRoute_Rurale,LEN(@vcRoute_Rurale),1) IN (' ','-',',','.',':',';')
								SET @vcRoute_Rurale = SUBSTRING(@vcRoute_Rurale,1,LEN(@vcRoute_Rurale)-1)

							-- Extraire de l'adresse tout le texte de la route rurale
							SET @vcTMP = ''
							IF @iPosDebut > 1
								SET @vcTMP = @vcTMP + SUBSTRING(@vcAdresse,1,@iPosDebut-1)
							IF @iPosDebut+@iLongueur1+@iCompteur <= LEN(@vcAdresse)
								SET @vcTMP = @vcTMP + SUBSTRING(@vcAdresse,@iPosDebut+@iLongueur1+@iCompteur,75)
							SET @vcAdresse = @vcTMP

							-- Ménage au début et à la fin de l'adresse
							SET @vcAdresse = LTRIM(RTRIM(@vcAdresse))

							WHILE LEN(@vcAdresse) > 0 AND SUBSTRING(@vcAdresse,1,1) IN (' ','-',',','.',':',';')
								SET @vcAdresse = SUBSTRING(@vcAdresse,2,75)

							WHILE LEN(@vcAdresse) > 0 AND SUBSTRING(@vcAdresse,LEN(@vcAdresse),1) IN (' ','-',',','.',':',';')
								SET @vcAdresse = SUBSTRING(@vcAdresse,1,LEN(@vcAdresse)-1)

							-- S'il n'y a pas de route rurale, s'assurer de retourner NULL
							IF LTRIM(RTRIM(@vcRoute_Rurale)) = ''
								SET @vcRoute_Rurale = NULL
						END
					-- Le préfixe est absent, retirer de l'inventaire des préfixes pour rechercher le suivant
					ELSE
						SET @vcListeCasePostale = SUBSTRING(@vcListeCasePostale,CHARINDEX('|',@vcListeCasePostale)+1,500)
				END
		END


	--------------------------------------------------------------
	-- Déterminer et extraire le numéro d’appartement de l’adresse 
	--------------------------------------------------------------
-- TODO: Utiliser des préfixes au lieu de juste APP/APT?
--		 Condo, suite, unité, chambre, Appartement, Appt, Appt.

	-- Rechercher "APP/APT"
	SET @iPosDebut = CHARINDEX('APP',UPPER(@vcAdresse))
	IF @iPosDebut = 0
		SET @iPosDebut = CHARINDEX('APT',UPPER(@vcAdresse))

	-- S'il y a un appartement "APP/APT"
	IF @iPosDebut > 0 AND
	   LEN(@vcAdresse) >= @iPosDebut+3 AND
	   SUBSTRING(@vcAdresse,@iPosDebut+3,1) IN (' ','.',',',':',';')
		BEGIN
			SET @iLongueur1 = 4
			SET @iAPP_APT = 1
		END
	-- S'il n'y a pas d'appartement "APP/APT"
	ELSE
		BEGIN
			-- Rechercher l'appartement au début de l'adresse et le "-" doit être suivi d'un chiffre de numéro civique
			SET @iPosTiret = CHARINDEX('-',@vcAdresse)
			IF @iPosTiret > 1 AND 
			   @iPosTiret <= 6 AND
			   LEN(@vcAdresse) > @iPosTiret AND 
			   (SUBSTRING(@vcAdresse,@iPosTiret+1,1) IN (' ','-',',','.') OR 
				(SUBSTRING(@vcAdresse,@iPosTiret+1,1) >= '0' AND SUBSTRING(@vcAdresse,@iPosTiret+1,1) <= '9'))
				BEGIN
					SET @iPosDebut = 1
					SET @iLongueur1 = 0
					SET @iAPP_APT = 0
				END
			-- Pas d'appartement au début de l'adresse
			ELSE
				BEGIN
					-- Rechercher l'appartement avec le dernier "#".
					SET @iPosTiret = CHARINDEX('#',REVERSE(@vcAdresse))
					IF @iPosTiret > 0
						SET @iPosTiret = LEN(@vcAdresse)-@iPosTiret+1
	
					-- Il doit être suivi d'un chiffre
					IF @iPosTiret > 0 AND 
					   LEN(@vcAdresse) > @iPosTiret AND 
					   (SUBSTRING(@vcAdresse,@iPosTiret+1,1) >= '0' AND SUBSTRING(@vcAdresse,@iPosTiret+1,1) <= '9')
						BEGIN
							SET @vcListePrefixe = 'Route rurale|Condos|Condo|Route|Suite|Unité|R. R.|Site|Rang|R.R.|R.R|Lot|RR.|RR|Rd|'
							SET @iAPP_APT = 0

							-- Rouler les préfixes à rechercher
							WHILE LEN(@vcListePrefixe) > 1
								BEGIN
									-- Rechercher un préfixe
									SET @vcElementRecherche = UPPER(SUBSTRING(@vcListePrefixe,1,CHARINDEX('|',@vcListePrefixe)-1))
									IF CHARINDEX(@vcElementRecherche,UPPER(@vcAdresse)) > 0 AND
									   CHARINDEX(@vcElementRecherche,UPPER(@vcAdresse)) IN (@iPosTiret-LEN(@vcElementRecherche),@iPosTiret-LEN(@vcElementRecherche)-1)
										BEGIN
											SET @iAPP_APT = 1
											SET @vcListePrefixe = ''
										END
									-- Le préfixe est absent, retirer de l'inventaire des préfixes pour rechercher le suivant
									ELSE
										SET @vcListePrefixe = SUBSTRING(@vcListePrefixe,CHARINDEX('|',@vcListePrefixe)+1,500)
								END

							IF @iAPP_APT = 0
								BEGIN
									SET @iAPP_APT = 1
									SET @iPosDebut = @iPosTiret
									SET @iLongueur1 = 1
								END
							ELSE
								SET @iPosDebut = 0
						END
					ELSE
						SET @iPosDebut = 0
				END
		END

	-- Si numéro d'appartement est trouvé
	IF @iPosDebut > 0
		BEGIN
			-- Trouver le début du numéro d'appartement
			SET @iCompteur = 0
			WHILE @iPosDebut+@iLongueur1+@iCompteur <= LEN(@vcAdresse) AND
				  SUBSTRING(@vcAdresse,@iPosDebut+@iLongueur1+@iCompteur,1) IN (' ','.',',',':',';')
				SET @iCompteur = @iCompteur + 1
			SET @iPosDebutElement = @iPosDebut + @iLongueur1 + @iCompteur
			SET @iLongueur1 = @iLongueur1 + @iCompteur
			
			-- Trouver la fin du numéro d'appartement
			SET @iCompteur = 0
			WHILE @iPosDebutElement+@iCompteur <= LEN(@vcAdresse) AND
				  ((@iAPP_APT = 1 AND SUBSTRING(@vcAdresse,@iPosDebutElement+@iCompteur,1) NOT IN (' ','.',',')) OR
				   (@iAPP_APT = 0 AND SUBSTRING(@vcAdresse,@iPosDebutElement+@iCompteur,1) NOT IN ('-')))
				SET @iCompteur = @iCompteur + 1

			-- Retenir le numéro d'appartement de l'adresse
			SET @vcNoApp = SUBSTRING(@vcAdresse,@iPosDebutElement,@iCompteur)

			-- Ménage au début et à la fin du numéro d'appartement
			WHILE LEN(@vcNoApp) > 0 AND SUBSTRING(@vcNoApp,1,1) IN (' ','-',',','.',':',';')
				SET @vcNoApp = SUBSTRING(@vcNoApp,2,75)

			WHILE LEN(@vcNoApp) > 0 AND SUBSTRING(@vcNoApp,LEN(@vcNoApp),1) IN (' ','-',',','.',':',';')
				SET @vcNoApp = SUBSTRING(@vcNoApp,1,LEN(@vcNoApp)-1)

			-- Extraire de l'adresse tout le texte de numéro d'appartement
			SET @vcTMP = ''
			IF @iPosDebut > 1
				SET @vcTMP = @vcTMP + SUBSTRING(@vcAdresse,1,@iPosDebut-1)
			IF @iPosDebut+@iLongueur1+@iCompteur <= LEN(@vcAdresse)
				SET @vcTMP = @vcTMP + SUBSTRING(@vcAdresse,@iPosDebut+@iLongueur1+@iCompteur,75)
			SET @vcAdresse = @vcTMP

			-- Ménage au début et à la fin de l'adresse
			SET @vcAdresse = LTRIM(RTRIM(@vcAdresse))

			WHILE LEN(@vcAdresse) > 0 AND SUBSTRING(@vcAdresse,1,1) IN (' ','-',',','.',':',';')
				SET @vcAdresse = SUBSTRING(@vcAdresse,2,75)

			WHILE LEN(@vcAdresse) > 0 AND SUBSTRING(@vcAdresse,LEN(@vcAdresse),1) IN (' ','-',',','.',':',';')
				SET @vcAdresse = SUBSTRING(@vcAdresse,1,LEN(@vcAdresse)-1)
		END

	-- S'il n'y a pas de numéro d'appartement, s'assurer de retourner NULL
	IF LTRIM(RTRIM(@vcNoApp)) = ''
		SET @vcNoApp = NULL


	--------------------------------------------------------
	-- Déterminer et extraire le numéro civique de l'adresse 
	--------------------------------------------------------

	-- Trouver la fin du premier mot
	SET @bCarNum = 0
	SET @iCompteur = 0
	WHILE @iCompteur+1 <= LEN(@vcAdresse) AND
		  SUBSTRING(@vcAdresse,@iCompteur+1,1) NOT IN (' ','.',',',':',';')
		BEGIN
			-- Déterminer s'il y a des chiffres
			IF SUBSTRING(@vcAdresse,@iCompteur+1,1) >= '0' AND
			   SUBSTRING(@vcAdresse,@iCompteur+1,1) <= '9'
				SET @bCarNum = 1
			SET @iCompteur = @iCompteur + 1
		END

	-- S'il y a un premier mot qu'il contient au moins 1 chiffre, considérer ce mot comme le numéro civique
	IF @iCompteur > 0 AND @bCarNum = 1
		BEGIN
			-- Retenir le numéro civique
			SET @vcNo_Civique = SUBSTRING(@vcAdresse,1,@iCompteur)

			-- Ménage à la fin du numéro civique
			WHILE LEN(@vcNo_Civique) > 0 AND SUBSTRING(@vcNo_Civique,LEN(@vcNo_Civique),1) IN (' ','-',',','.',':',';')
				SET @vcNo_Civique = SUBSTRING(@vcNo_Civique,1,LEN(@vcNo_Civique)-1)

			-- Extraire de l'adresse tout le texte du numéro civique
			IF @iCompteur+1 <= LEN(@vcAdresse)
				SET @vcAdresse = SUBSTRING(@vcAdresse,@iCompteur+1,75)
			ELSE
				SET @vcAdresse = ''

			-- Ménage au début de l'adresse
			SET @vcAdresse = LTRIM(RTRIM(@vcAdresse))

			WHILE LEN(@vcAdresse) > 0 AND SUBSTRING(@vcAdresse,1,1) IN (' ','-',',','.',':',';')
				SET @vcAdresse = SUBSTRING(@vcAdresse,2,75)
		END


	-----------------------------------------------------
	-- Déterminer et extraire le type de rue de l'adresse 
	-----------------------------------------------------

	IF @bSeparer_Type_Rue = 1
		BEGIN
			-- Inventaire des préfixes à rechercher
			-- Note importante: Mettre les préfixes en ordre d'importance et descendant de nombre de caractère de la chaine recherchée
			SET @vcListeTypeRue = 'Rue,Rue|Avenue,Avenue|Ave.,Avenue|Ave,Avenue|av.,Avenue|av,Avenue|Boulevard,Boulevard|Boul.,Boulevard|Boul,Boulevard|Bl.,Boulevard|'+
								  'Chemin,Chemin|Ch.,Chemin|ch,Chemin|Rang,Rang|'+
								  'Route rurale,Route rurale|R. R.,Route rurale|R.R.,Route rurale|R.R,Route rurale|RR.,Route rurale|RR,Route rurale|Route,Route|Rte,Route|'+
								  'Place,Place|Côte,Côte|Montée,Montée|Carré,Carré|Allée,Allée|Terrasse,Terrasse|Tsse,Terrasse|Croissant,Croissant|Court,Court|Promenade,Promenade|'+
								  'Street,Street|St,Street|Drive,Drive|Dr,Drive|Road,Road|Rd,Road|Lane,Lane|Crescent,Crescent|Crt.,Crescent|Cres,Crescent|Gate,Gate|Way,Way|Ridge,Ridge|Circle,Circle|'
			SET @vcType_Rue = NULL

			-- Rouler les préfixes à rechercher
			WHILE LEN(@vcListeTypeRue) > 1 AND
				  LEN(@vcAdresse) > 0 AND 
				  @vcType_Rue IS NULL
				BEGIN
					-- Rechercher un préfixe
					SET @vcElementRecherche = UPPER(SUBSTRING(@vcListeTypeRue,1,CHARINDEX(',',@vcListeTypeRue)-1))
					SET @vcElementCorrige = SUBSTRING(@vcListeTypeRue,LEN(@vcElementRecherche)+2,CHARINDEX('|',@vcListeTypeRue)-2-LEN(@vcElementRecherche))
					SET @iPosDebut = CHARINDEX(@vcElementRecherche,UPPER(@vcAdresse))

					-- Le préfixe est présent et il est suivi d'un caractère significatif indiquant qu'il est
					-- précédé d'un caractère séparateur pour que les caractères recherché fasse un mot complet et ne soit pas qu'une partie d'un autre mot
					IF @iPosDebut > 0 AND 
					   ((@iPosDebut = 1 AND LEN(@vcAdresse) > LEN(@vcElementRecherche) AND SUBSTRING(@vcAdresse,LEN(@vcElementRecherche)+1,1) IN (' ',',')) OR
						(@iPosDebut > 1 AND SUBSTRING(@vcAdresse,@iPosDebut-1,1) IN (' ',',') AND
							 (@iPosDebut+LEN(@vcElementRecherche) > LEN(@vcAdresse) OR SUBSTRING(@vcAdresse,@iPosDebut+LEN(@vcElementRecherche),1) IN (' ',','))))
						BEGIN
							-- Retenir le type de rue corrigé
							SET @vcType_Rue = @vcElementCorrige

							-- Extraire de l'adresse tout le texte du type de rue
							SET @vcTMP = ''
							IF @iPosDebut > 1
								SET @vcTMP = @vcTMP + SUBSTRING(@vcAdresse,1,@iPosDebut-1)
							IF @iPosDebut+LEN(@vcElementRecherche) <= LEN(@vcAdresse)
								SET @vcTMP = @vcTMP + SUBSTRING(@vcAdresse,@iPosDebut+LEN(@vcElementRecherche),75)
							SET @vcAdresse = @vcTMP

							-- Ménage au début et à la fin de l'adresse
							SET @vcAdresse = LTRIM(RTRIM(@vcAdresse))

							WHILE LEN(@vcAdresse) > 0 AND SUBSTRING(@vcAdresse,1,1) IN (' ','-',',','.',':',';')
								SET @vcAdresse = SUBSTRING(@vcAdresse,2,75)

							WHILE LEN(@vcAdresse) > 0 AND SUBSTRING(@vcAdresse,LEN(@vcAdresse),1) IN (' ','-',',','.',':',';')
								SET @vcAdresse = SUBSTRING(@vcAdresse,1,LEN(@vcAdresse)-1)

							WHILE CHARINDEX('  ',@vcAdresse) > 0
								SET @vcAdresse = REPLACE(@vcAdresse,'  ',' ')
						END
					-- Le préfixe est absent, retirer de l'inventaire des préfixes pour rechercher le suivant
					ELSE
						SET @vcListeTypeRue = SUBSTRING(@vcListeTypeRue,CHARINDEX('|',@vcListeTypeRue)+1,1000)
				END
		END


	---------------------------------
	-- Déterminer la rue de l'adresse 
	---------------------------------

	SET @vcRue = NULL
	SET @vcChaine = LOWER(@vcAdresse)
	IF @vcChaine IS NOT NULL AND @vcChaine <> ''
		BEGIN
			-- Mettre en minuscule, la première lettre en majuscule.
			-- Note: Fonction "fnGENE_ObtenirPremiereLettre_EnMajuscule" pas satisfaisante
			SET @iCompteur = 1
			SET @bMot = 0
			WHILE @iCompteur <= LEN(@vcChaine)
				BEGIN
					-- Considérer un nouveau mot sur les caractères séparateurs
					IF SUBSTRING(@vcChaine,@iCompteur,1) IN (' ',',','-',':',';','''','.','/','\')
						SET @bMot = 0
					ELSE
						BEGIN
							-- Sur la première lettre d'un mot, mettre en majuscule
							IF @bMot = 0 AND SUBSTRING(@vcChaine,@iCompteur,1) BETWEEN 'a' AND 'z'  
								BEGIN
									SET @vcTMP = ''
									IF @iCompteur > 1
										SET @vcTMP = @vcTMP + SUBSTRING(@vcChaine,1,@iCompteur-1)
									SET @vcTMP = @vcTMP + UPPER(SUBSTRING(@vcChaine,@iCompteur,1))
									IF @iCompteur+1 <= LEN(@vcChaine)
										SET @vcTMP = @vcTMP + SUBSTRING(@vcChaine,@iCompteur+1,75)
									SET @vcChaine = @vcTMP
								END
							SET @bMot = 1
						END

					SET @iCompteur  = @iCompteur  + 1 
				END

			-- Améliorer la casse
			SET @vcChaine = REPLACE(@vcChaine,' Du ' ,' du ')
			SET @vcChaine = REPLACE(@vcChaine,' De ' ,' de ')
			SET @vcChaine = REPLACE(@vcChaine,' Des ' ,' des ')
			SET @vcChaine = REPLACE(@vcChaine,' La ' ,' la ')
			SET @vcChaine = REPLACE(@vcChaine,' Et ' ,' et ')
			SET @vcChaine = REPLACE(@vcChaine,'-Du-' ,'-du-')
			SET @vcChaine = REPLACE(@vcChaine,'-De-' ,'-de-')
			SET @vcChaine = REPLACE(@vcChaine,'-Des-' ,'-des-')
			SET @vcChaine = REPLACE(@vcChaine,'-La-' ,'-la-')
			SET @vcChaine = REPLACE(@vcChaine,'-Aux-' ,'-aux-')
			SET @vcChaine = REPLACE(@vcChaine,' L''' ,' l''')
			SET @vcChaine = REPLACE(@vcChaine,' D''' ,' d''')

			IF LEFT(@vcChaine,3) IN ('Du ','De ','La ')
				SET @vcChaine = LOWER(LEFT(@vcChaine,1))+RIGHT(@vcChaine,LEN(@vcChaine)-1)

			IF LEFT(@vcChaine,4) IN ('Des ')
				SET @vcChaine = LOWER(LEFT(@vcChaine,1))+RIGHT(@vcChaine,LEN(@vcChaine)-1)

			-- Améliorer la présentation
			SET @vcChaine = REPLACE(@vcChaine,', ,' ,',')
			SET @vcChaine = REPLACE(@vcChaine,',,' ,',')
			SET @vcChaine = REPLACE(@vcChaine,'  ' ,' ')
			SET @vcChaine = REPLACE(@vcChaine,' , ' ,', ')

			IF @vcChaine IS NOT NULL AND @vcChaine <> ''
				SET @vcRue = @vcChaine
		END

	----------------------------------------------------
	-- Améliorer la cohérence de l'ensemble de l'adresse
	----------------------------------------------------
	IF @vcNo_Civique IS NOT NULL AND
	   @vcType_Rue IS NULL AND
	   @vcRue IS NULL AND
	   SUBSTRING(@vcNo_Civique,1,1) NOT BETWEEN '0' AND '9' 
		BEGIN
--			-- Déterminer s'il y a que des lettres
--			SET @iCompteur = 1
--			SET @bMot = 0
--			WHILE @iCompteur <= LEN(@vcNo_Civique)
--				BEGIN
--					IF SUBSTRING(@vcNo_Civique,@iCompteur,1) NOT BETWEEN '0' AND '9'  
--						SET @bMot = 1
--					SET @iCompteur  = @iCompteur  + 1 
--				END


			SET @vcRue = @vcNo_Civique
			SET @vcNo_Civique = NULL
		END

	-- Retourner les valeurs
	INSERT @tblGENE_Adresse (vcNo_Civique,vcRue,vcNo_Appartement,vcType_Rue,vcCase_Postale,vcRoute_Rurale)
					 VALUES (SUBSTRING(@vcNo_Civique,1,10),SUBSTRING(@vcRue,1,75),SUBSTRING(@vcNoApp,1,10),SUBSTRING(@vcType_Rue,1,20),SUBSTRING(@vcCase_Postale,1,10),SUBSTRING(@vcRoute_Rurale,1,10))

	RETURN
END
